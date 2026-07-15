# diff-lines.awk — parse a unified diff (git/gh format).
#
# Two modes, selected via -v MODE=...:
#   commentable : emit one "path<TAB>side<TAB>line" row per line that GitHub will
#                 accept an inline review comment on. Used to validate/filter
#                 findings before posting so the reviews API doesn't 422 on a bad
#                 anchor (it rejects the ENTIRE review if any one comment is off).
#   annotate    : re-emit the diff with an "old new" line-number gutter so the
#                 reviewer can read exact line numbers to anchor comments to.
#
# Portable: uses only POSIX awk features (no gawk 3-arg match / gensym).

BEGIN { newpath=""; oldpath=""; newLine=0; oldLine=0; inhunk=0 }

{
  line = $0

  # File headers reset hunk state. Capture both old (LEFT) and new (RIGHT) paths.
  if (line ~ /^diff --git /) { inhunk=0; next }
  if (line ~ /^--- /) {
    p=line; sub(/^--- /,"",p)
    if (p=="/dev/null") oldpath=""; else { sub(/^a\//,"",p); oldpath=p }
    inhunk=0; next
  }
  if (line ~ /^\+\+\+ /) {
    p=line; sub(/^\+\+\+ /,"",p)
    if (p=="/dev/null") newpath=""; else { sub(/^b\//,"",p); newpath=p }
    inhunk=0; next
  }

  # Hunk header: @@ -oldStart,oldCount +newStart,newCount @@ [heading]
  if (line ~ /^@@ /) {
    old=$2; new=$3
    sub(/^-/,"",old); sub(/^\+/,"",new)
    split(new,na,","); newLine=na[1]+0
    split(old,oa,","); oldLine=oa[1]+0
    inhunk=1
    if (MODE=="annotate") printf "            %s\n", line
    next
  }

  if (!inhunk) next

  c = substr(line,1,1)
  rest = substr(line,2)

  if (c=="+") {                                   # addition — RIGHT side only
    if (MODE=="commentable") { if (newpath!="") emit(newpath,"RIGHT",newLine) }
    else annot("",newLine,"+",rest)
    newLine++
  } else if (c=="-") {                            # deletion — LEFT side only
    if (MODE=="commentable") { if (oldpath!="") emit(oldpath,"LEFT",oldLine) }
    else annot(oldLine,"","-",rest)
    oldLine++
  } else if (c==" ") {                            # context — both sides
    if (MODE=="commentable") { if (newpath!="") emit(newpath,"RIGHT",newLine) }
    else annot(oldLine,newLine," ",rest)
    newLine++; oldLine++
  } else if (c=="\\") {                           # "\ No newline at end of file"
    # not a real line; ignore
  } else {
    inhunk=0                                       # anything else ends the hunk
  }
}

function emit(path,side,ln) { printf "%s\t%s\t%d\n", path, side, ln }
function annot(o,n,sym,txt) { printf "%5s %5s %s%s\n", o, n, sym, txt }
