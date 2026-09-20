# Targeted JSON Schema checker for the draft-07 subset the devkit schemas actually use.
# Not a conformance validator: it implements exactly the keywords listed in `keywords`
# and refuses to run against a schema that uses anything else, so adding a keyword to
# schemas/*.json fails loudly here instead of being silently ignored.
#
# Inputs: $schema, $doc, $label. Output: one error line per violation, none when valid.

def keywords: ["$schema", "$id", "title", "description", "type", "required",
               "additionalProperties", "properties", "const", "enum", "pattern",
               "items", "uniqueItems"];

def jtype: if type == "number" and . == floor then "integer" else type end;

def check($s; $d; $p):
  ( $s | keys_unsorted[] | select(IN(keywords[]) | not)
    | "\($p): schema keyword `\(.)` is not implemented by schema-validate.jq" ),

  ( if ($s | has("type")) and ($d | jtype) != $s.type
       and (($s.type == "number" and ($d | type) == "number") | not)
    then "\($p): expected \($s.type), got \($d | type)"
    else empty end ),

  ( if ($s | has("const")) and $d != $s.const
    then "\($p): must be \($s.const | tojson), got \($d | tojson)"
    else empty end ),

  ( if ($s | has("enum")) and ($s.enum | index($d)) == null
    then "\($p): must be one of \($s.enum | join(", ")), got \($d | tojson)"
    else empty end ),

  ( if ($s | has("pattern")) and ($d | type) == "string" and ($d | test($s.pattern) | not)
    then "\($p): \($d | tojson) does not match \($s.pattern)"
    else empty end ),

  ( if $s.uniqueItems == true and ($d | type) == "array" and ($d | unique | length) != ($d | length)
    then "\($p): contains duplicate entries"
    else empty end ),

  ( if ($d | type) == "object"
    then
      ( ($s.required // [])[] as $k | select(($d | has($k)) | not)
        | "\($p): missing required key `\($k)`" ),
      ( if $s.additionalProperties == false
        then ($d | keys[]) as $k | select((($s.properties // {}) | has($k)) | not)
             | "\($p): unknown key `\($k)`"
        else empty end ),
      ( $s.properties // {} | keys[] as $k | select($d | has($k))
        | check($s.properties[$k]; $d[$k]; "\($p).\($k)") )
    else empty end ),

  ( if ($d | type) == "array" and ($s | has("items"))
    then range(0; $d | length) as $i | check($s.items; $d[$i]; "\($p)[\($i)]")
    else empty end );

check($schema; $doc; $label)
