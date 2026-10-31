#!/usr/bin/env python3
import argparse
import datetime as dt
import json
import math
from pathlib import Path
import sys
from urllib.parse import urlsplit


KINDS = {"automatic", "banked", "paid", "allowance_change", "scheduled", "unknown"}
STATUSES = {"announced", "observed", "confirmed", "retracted"}
SCOPES = {"main", "model", "feature", "unknown"}
DELIVERED = {"observed", "confirmed"}


def timestamp(value):
    if not isinstance(value, str):
        raise ValueError("timestamps must be ISO strings")
    parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None or parsed.utcoffset() is None:
        raise ValueError("timestamps require an explicit timezone")
    return parsed.astimezone(dt.timezone.utc)


def effective_date(value):
    if not isinstance(value, str):
        raise ValueError("effective_at must be an ISO date or aware timestamp")
    return dt.date.fromisoformat(value) if len(value) == 10 else timestamp(value).date()


def validate(history):
    if history["provider"] != "codex":
        raise ValueError("this history calculator supports provider=codex")
    updated = timestamp(history["updated_at"])
    coverage = history["coverage"]
    start, end = (dt.date.fromisoformat(coverage[k]) for k in ("start", "end"))
    if start >= end or not isinstance(coverage["complete"], bool):
        raise ValueError("coverage needs start < end and a boolean complete flag")
    for gap in coverage.get("gaps", []):
        lo, hi = (dt.date.fromisoformat(gap[k]) for k in ("start", "end"))
        if not start <= lo < hi <= end:
            raise ValueError("coverage gaps must be nonempty intervals inside the surveyed date span")
    if not isinstance(history["events"], list):
        raise ValueError("events must be a list")
    seen = set()
    for event in history["events"]:
        identity = event["id"]
        if not isinstance(identity, str) or not identity.strip() or identity in seen:
            raise ValueError("events require unique, nonempty canonical IDs")
        seen.add(identity)
        if event["kind"] not in KINDS or event["status"] not in STATUSES or event["scope"] not in SCOPES:
            raise ValueError(f"invalid classification for {identity}")
        plans, sources = event["plans"], event["source_urls"]
        if not isinstance(plans, list) or any(not isinstance(p, str) or not p.strip() for p in plans):
            raise ValueError(f"plans must be a list of nonempty strings: {identity}")
        if not isinstance(sources, list) or not sources:
            raise ValueError(f"source URLs are required: {identity}")
        for source in sources:
            if not isinstance(source, str):
                raise ValueError(f"source URLs must be strings: {identity}")
            parsed = urlsplit(source)
            if parsed.scheme not in {"https", "http"} or not parsed.netloc or parsed.username or parsed.password:
                raise ValueError(f"use public HTTP(S) source URLs without credentials: {identity}")
        if event.get("effective_at") is not None:
            effective_date(event["effective_at"])
        if event.get("announced_at") is not None:
            timestamp(event["announced_at"])
        if event["kind"] == "automatic" and event["status"] in DELIVERED and not event.get("effective_at"):
            raise ValueError(f"delivered automatic reset needs effective_at: {identity}")
    return start, end, updated


def poisson_cdf(count, mean):
    if mean == 0:
        return 1.0
    terms = [i * math.log(mean) - math.lgamma(i + 1) for i in range(count + 1)]
    largest = max(terms)
    return min(1.0, math.exp(largest - mean) * sum(math.exp(v - largest) for v in terms))


def invert_cdf(count, target):
    low, high = 0.0, max(1.0, count + 1.0)
    while poisson_cdf(count, high) > target:
        high *= 2
    for _ in range(80):
        middle = (low + high) / 2
        if poisson_cdf(count, middle) > target:
            low = middle
        else:
            high = middle
    return (low + high) / 2


def probability(rate, hours):
    return -math.expm1(-rate * hours / 24)


def scenario(count, days, horizons):
    if days == 0:
        return {"events": count, "events_per_day": None,
                "horizons": [{"hours": h, "probability": None, "poisson_sampling_interval_95": None} for h in horizons]}
    low = invert_cdf(count - 1, 0.975) / days if count else 0.0
    high = invert_cdf(count, 0.025) / days
    rate = count / days
    return {
        "events": count,
        "events_per_day": round(rate, 6),
        "horizons": [{"hours": h, "probability": round(probability(rate, h), 6),
                      "poisson_sampling_interval_95": [round(probability(low, h), 6),
                                                       round(probability(high, h), 6)]} for h in horizons],
    }


def eligible_events(start, end, events, plan, gaps=frozenset()):
    return [e for e in events if e["kind"] == "automatic" and e["status"] in DELIVERED
                 and e["scope"] in {"main", "unknown"} and e.get("effective_at")
                 and start <= effective_date(e["effective_at"]) < end
                 and effective_date(e["effective_at"]) not in gaps
                 and (not e["plans"] or plan in e["plans"])]


def window(label, start, end, events, plan, horizons, gaps=frozenset()):
    delivered = eligible_events(start, end, events, plan, gaps)
    known = [e for e in delivered if plan in e["plans"] and e["scope"] == "main"]
    days = (end - start).days - sum(start <= day < end for day in gaps)
    return {"label": label, "start_inclusive_utc": start.isoformat(), "end_exclusive_utc": end.isoformat(),
            "calendar_span_days": (end - start).days, "exposure_days": days,
            "known_eligible_main": scenario(len(known), days, horizons),
            "including_unknown_applicability": scenario(len(delivered), days, horizons),
            "event_ids": [e["id"] for e in delivered]}


def dynamic_scenarios(start, end, events, plan, horizons, half_lives, gaps=frozenset()):
    delivered = eligible_events(start, end, events, plan, gaps)
    known = [e for e in delivered if plan in e["plans"] and e["scope"] == "main"]
    observed = [start + dt.timedelta(days=i) for i in range((end - start).days)
                if start + dt.timedelta(days=i) not in gaps]
    if not observed:
        return {"scenarios": [], "limitation": "No surveyed complete days; dynamic estimates unavailable."}
    newest = max(observed)
    scenarios = []
    for half_life in half_lives:
        weight = lambda day: 2 ** (-(newest - day).days / half_life)
        exposure = sum(weight(day) for day in observed)
        row = {"half_life_days": half_life, "weighted_exposure_days": round(exposure, 6)}
        for key, selected in (("known_eligible_main", known), ("including_unknown_applicability", delivered)):
            count = sum(weight(effective_date(event["effective_at"])) for event in selected)
            rate = count / exposure
            row[key] = {"weighted_events": round(count, 6), "events_per_day": round(rate, 6),
                        "horizons": [{"hours": h, "probability": round(probability(rate, h), 6)} for h in horizons]}
        scenarios.append(row)
    return {"start_inclusive_utc": start.isoformat(), "end_exclusive_utc": end.isoformat(),
            "method": "Exponential calendar-day weights; weight=2^(-age_days/half_life); current weighted rate held constant over forecast horizon",
            "scenarios": scenarios,
            "limitation": "Half-life sensitivity is not a confidence interval; future intensity and account applicability remain uncertain."}


def recent_change(first, end, events, plan, horizons, gaps=frozenset()):
    middle = end - dt.timedelta(days=30)
    start = max(first, middle - dt.timedelta(days=30))
    if start >= middle:
        return {"direction": "insufficient_coverage", "reason": "Two nonoverlapping 30-day periods are unavailable"}
    prior = window("preceding_30_days", start, middle, events, plan, horizons, gaps)
    recent = window("recent_30_days", middle, end, events, plan, horizons, gaps)
    direction = "insufficient_coverage"
    ratio = None
    if prior["exposure_days"] == recent["exposure_days"] == 30:
        a = prior["including_unknown_applicability"]["events_per_day"]
        b = recent["including_unknown_applicability"]["events_per_day"]
        ratio = round(b / a, 4) if a else None
        direction = "rising" if b > 1.5 * a else "falling" if a > 1.5 * b else "similar"
    return {"direction": direction, "recent_to_prior_rate_ratio": ratio, "prior": prior, "recent": recent,
            "limitation": "Descriptive change, not a tested regime shift or proof that the trend will continue."}


def analyze(history, as_of, plan, days, horizons, half_lives=(14, 30, 60)):
    first, covered_end, updated = validate(history)
    if updated > as_of:
        raise ValueError("history updated_at is later than --as-of; historical backtesting is not supported")
    for event in history["events"]:
        effective = event.get("effective_at")
        if effective and event["status"] in DELIVERED:
            future = effective_date(effective) > as_of.date() if len(effective) == 10 else timestamp(effective) > as_of
            if future:
                raise ValueError(f"delivered event is dated in the future: {event['id']}")
    end = min(covered_end, as_of.date())
    if first >= end:
        raise ValueError("history contains no complete UTC days before --as-of")
    warnings = ["Constant-rate Poisson scenarios are not calibrated forecasts or guarantees for this account.",
                "Sampling intervals exclude missing events, classification errors and changes in reset behavior."]
    if not history["coverage"]["complete"]:
        warnings.append("Public history is incomplete; missing records cannot be treated as known event-free days.")
    age = (as_of - updated).total_seconds() / 3600
    if age > 24:
        warnings.append("History refresh is older than 24 hours; refresh before acting.")
    if end < as_of.date():
        warnings.append("Surveyed history ends before the latest complete UTC day.")
    events = history["events"]
    gaps = set()
    for gap in history["coverage"].get("gaps", []):
        lo, hi = (dt.date.fromisoformat(gap[k]) for k in ("start", "end"))
        gaps.update(lo + dt.timedelta(days=i) for i in range((hi - lo).days))
    if gaps:
        warnings.append("Known unsurveyed dates are excluded from event counts and exposure, including dynamic weights.")
    results = []
    for length in sorted(set(days)):
        requested = as_of.date() - dt.timedelta(days=length)
        start = max(first, requested)
        if start >= end:
            continue
        row = window(f"last_{length}_complete_days", start, end, events, plan, horizons, gaps)
        row["requested_days"] = length
        if row["exposure_days"] < length:
            warnings.append(f"{row['label']} has only {row['exposure_days']} surveyed days.")
        results.append(row)
    if not results:
        raise ValueError("requested lookbacks do not overlap surveyed complete days")
    month_start = max(first, as_of.date() - dt.timedelta(days=max(days))).replace(day=1)
    monthly = []
    while month_start < end:
        next_month = (month_start.replace(day=28) + dt.timedelta(days=4)).replace(day=1)
        lo, hi = max(first, month_start, as_of.date() - dt.timedelta(days=max(days))), min(end, next_month)
        if lo < hi:
            monthly.append(window(month_start.strftime("%Y-%m"), lo, hi, events, plan, horizons, gaps))
        month_start = next_month
    short, long = results[0], results[-1]
    recent_rate = short["including_unknown_applicability"]["events_per_day"]
    baseline_rate = long["including_unknown_applicability"]["events_per_day"]
    if (len(results) > 1 and recent_rate is not None and baseline_rate is not None
            and max(recent_rate, baseline_rate) > 1.5 * min(recent_rate, baseline_rate)):
        warnings.append("Recent and pooled reset frequencies differ materially; compare regimes instead of pooling blindly.")
    dynamic_start = max(first, as_of.date() - dt.timedelta(days=max(days)))
    dynamic = dynamic_scenarios(dynamic_start, end, events, plan, horizons, half_lives, gaps)
    change = recent_change(first, end, events, plan, horizons, gaps)
    delivered_today, pending = [], []
    for event in events:
        if event["kind"] != "automatic" or event["scope"] not in {"main", "unknown"}:
            continue
        if event["plans"] and plan not in event["plans"]:
            continue
        if event["status"] == "announced":
            pending.append(event["id"])
        elif event["status"] in DELIVERED:
            value = event["effective_at"]
            if effective_date(value) == as_of.date() and (len(value) == 10 or timestamp(value) <= as_of):
                delivered_today.append(event["id"])
    counted = {identity for row in results for identity in row["event_ids"]}
    return {"as_of_utc": as_of.isoformat(), "plan": plan, "history_age_hours": round(age, 2),
            "method": "P(N>=1 in h)=1-exp(-(events/exposure_days)*h/24); constant-rate Poisson",
            "monthly": monthly, "lookbacks": results, "delivered_today_excluded_from_rates": delivered_today,
            "dynamic": dynamic, "recent_change": change,
            "announced_automatic_not_counted": pending,
            "counted_evidence": [e for e in events if e["id"] in counted],
            "warnings": warnings, "history_notes": history.get("notes", [])}


def main():
    parser = argparse.ArgumentParser(description="Analyze verified automatic Codex resets; never redeem a reset.")
    parser.add_argument("--history", required=True, help="Normalized public history JSON, or - for stdin")
    parser.add_argument("--as-of", required=True, help="Aware ISO timestamp")
    parser.add_argument("--plan", required=True, help="Normalized plan family, such as pro")
    parser.add_argument("--days", type=int, nargs="+", default=[14, 30, 60, 90, 180])
    parser.add_argument("--half-life-days", type=float, nargs="+", default=[14, 30, 60],
                        help="Recency-weighted rate sensitivity; these are not confidence bounds")
    parser.add_argument("--horizon-hours", type=float, nargs="+", default=[24, 48])
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    if any(d < 1 for d in args.days) or any(not math.isfinite(h) or h <= 0 for h in args.horizon_hours + args.half_life_days):
        parser.error("lookbacks, finite horizon hours and half-lives must be positive")
    try:
        raw = sys.stdin.read() if args.history == "-" else Path(args.history).read_text()
        result = analyze(json.loads(raw), timestamp(args.as_of), args.plan.lower(), args.days, args.horizon_hours,
                         args.half_life_days)
        rendered = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
        if args.out:
            args.out.parent.mkdir(parents=True, exist_ok=True)
            args.out.write_text(rendered)
        else:
            sys.stdout.write(rendered)
    except (ValueError, KeyError, TypeError, OSError) as exc:
        parser.error(str(exc))


if __name__ == "__main__":
    main()
