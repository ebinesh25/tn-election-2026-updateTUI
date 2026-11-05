#!/usr/bin/env bash
# Tamil Nadu Election 2026 - btop-style Live TUI

for cmd in curl jq tput; do
  command -v "$cmd" &>/dev/null || { echo "Missing: $cmd"; exit 1; }
done

REFRESH=10
URL="https://results.eci.gov.in/ResultAcGenMay2026/election-json-S22-live.json"
TOTAL_SEATS=234
MAJORITY=118

R='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'
cRED='\033[38;5;196m'; cGREEN='\033[38;5;40m'; cBLUE='\033[38;5;39m'
cCYAN='\033[38;5;51m'; cYELLOW='\033[38;5;226m'; cMAG='\033[38;5;201m'
cORANGE='\033[38;5;214m'; cWHITE='\033[38;5;255m'; cGRAY='\033[38;5;244m'
cDARK='\033[38;5;238m'; cTEAL='\033[38;5;36m'; cLIME='\033[38;5;154m'
bgHEAD='\033[48;5;17m'; bgPANEL='\033[48;5;235m'; bgSTATUS='\033[48;5;232m'

party_color() {
  case "$1" in
    TVK) printf '%b' "$cMAG"    ;;
    DMK) printf '%b' "$cGREEN"  ;;
    ADMK) printf '%b' "$cYELLOW";;
    BJP)  printf '%b' "$cORANGE";;
    INC)  printf '%b' "$cBLUE"  ;;
    PMK)  printf '%b' "$cTEAL"  ;;
    AMMK) printf '%b' '\033[38;5;208m' ;;
    VCK)  printf '%b' "$cLIME"  ;;
    MDMK) printf '%b' '\033[38;5;70m' ;;
    CPI|"CPI(M)") printf '%b' "$cRED" ;;
    IUML) printf '%b' '\033[38;5;28m' ;;
    DMDK) printf '%b' '\033[38;5;220m';;
    *)    printf '%b' "$cWHITE" ;;
  esac
}

at()       { printf '\033[%d;%dH' "$1" "$2"; }
cols()     { tput cols;  }
rows()     { tput lines; }
clrscr()   { printf '\033[2J\033[H'; }
clear_row(){ at "$1" 1; printf '\033[2K'; }

hbar() {
  local val=$1 max=$2 w=$3 col="$4"
  local fill=0 empty
  (( max > 0 )) && fill=$(( val * w / max ))
  (( fill > w )) && fill=$w
  empty=$(( w - fill ))
  printf '%b' "$col"
  (( fill  > 0 )) && printf '%.0s█' $(seq 1 "$fill")
  printf '%b' "$cDARK"
  (( empty > 0 )) && printf '%.0s░' $(seq 1 "$empty")
  printf '%b' "$R"
}

sepline() {
  clear_row "$1"
  printf '%b' "$cDARK"
  printf '%.0s─' $(seq 1 "$(cols)")
  printf '%b' "$R"
}

fetch() { curl -sf --max-time 8 "$URL" 2>/dev/null || echo '{}'; }

seat_tally() {
  echo "$1" | jq -r '(.S22.tableData//[])|group_by(.[0])|map({k:.[0][0],v:length})|sort_by(-.v)[]|"\(.k)\t\(.v)"' 2>/dev/null
}
cand_list() {
  echo "$1" | jq -r '(.S22.chartData//[])|map(select(.[3]!="NA"))|sort_by(.[2])[]|"\(.[2])\t\(.[0])\t\(.[3])"' 2>/dev/null
}
count_party() {
  echo "$1" | jq --arg p "$2" '[(.S22.tableData//[])[]|select(.[0]==$p)]|length' 2>/dev/null || echo 0
}
total_decl() {
  echo "$1" | jq '(.S22.tableData//[])|length' 2>/dev/null || echo 0
}

draw() {
  local json="$1" ts="$2"
  local W H
  W=$(cols); H=$(rows)

  # HEADER
  clear_row 1
  printf '%b' "${bgHEAD}${cWHITE}${BOLD}"
  printf '%-'"$W"'s' ""
  local ttl="  TAMIL NADU ELECTION 2026 - LIVE  "
  local title_col=$(( (W - ${#ttl}) / 2 ))
  (( title_col < 1 )) && title_col=1
  at 1 "$title_col"
  printf '%s' "$ttl"
  printf '%b' "$R"

  clear_row 2
  at 2 2
  printf '%b' "${cCYAN}${DIM}"
  printf 'refresh %ds  |  last %s  |  seats %d  |  majority %d' \
    "$REFRESH" "$ts" "$TOTAL_SEATS" "$MAJORITY"
  printf '%b' "$R"
  sepline 3

  # LEFT: Tally
  local lw=$(( W/2 - 2 ))
  local bw=$(( lw - 24 )); (( bw < 6 )) && bw=6

  clear_row 4
  printf '%b' "${bgPANEL}${cCYAN}${BOLD}"
  printf '%-'"$lw"'s' "  SEAT TALLY"
  printf '%b' "$R"

  local tally; tally=$(seat_tally "$json")
  local max_c=1
  while IFS=$'\t' read -r _ c; do (( c > max_c )) && max_c=$c; done <<< "$tally"

  local row=5 shown=0 max_show=$(( H - 14 ))
  (( max_show < 3 )) && max_show=3

  while IFS=$'\t' read -r party count; do
    (( shown >= max_show )) && break
    (( shown++ ))
    local pct=$(( count * 100 / TOTAL_SEATS ))
    local star=""; (( count >= MAJORITY )) && star=" ✦"
    local pc; pc=$(party_color "$party")
    clear_row "$row"
    printf '%b%b%-8s%b ' "$pc" "$BOLD" "$party" "$R"
    hbar "$count" "$max_c" "$bw" "$pc"
    printf '%b%b%4d%b%b %3d%%%s%b' "$pc" "$BOLD" "$count" "$R" "$cGRAY" "$pct" "$star" "$R"
    (( row++ ))
  done <<< "$tally"

  local left_end=$(( H - 10 ))
  (( left_end < row )) && left_end=$row
  while (( row <= left_end )); do
    clear_row "$row"
    if (( row == left_end )); then
      printf '%b%-'"$lw"'s%b' "${cYELLOW}${DIM}" "  majority mark: 118" "$R"
    fi
    (( row++ ))
  done

  # RIGHT: Candidates
  local rx=$(( W/2 + 2 ))
  local rw=$(( W - rx ))

  at 4 "$rx"
  printf '%b' "${bgPANEL}${cCYAN}${BOLD}"
  printf '%-'"$rw"'s' "  CONSTITUENCIES"
  printf '%b' "$R"

  local cands; cands=$(cand_list "$json")
  local cr=5 cmax=$(( H - 12 ))

  while IFS=$'\t' read -r seat party name; do
    (( cr > cmax + 4 )) && break
    local nlen=$(( rw - 14 )); (( nlen < 4 )) && nlen=4
    local pc; pc=$(party_color "$party")
    at "$cr" "$rx"
    printf '%*s' "$rw" ""
    at "$cr" "$rx"
    printf '%b%3s %b' "$cGRAY" "$seat" "$R"
    printf '%b%b%-7s%b' "$pc" "$BOLD" "$party" "$R"
    printf '%b%-'"$nlen"'.'"$nlen"'s%b' "$cWHITE" "$name" "$R"
    (( cr++ ))
  done <<< "$cands"
  while (( cr <= cmax + 4 )); do
    at "$cr" "$rx"
    printf '%*s' "$rw" ""
    (( cr++ ))
  done

  # ALLIANCE SUMMARY
  local ab=$(( H - 8 ))
  sepline "$ab"; (( ab++ ))
  clear_row "$ab"; printf '%b  ALLIANCE SUMMARY%b\n' "${cWHITE}${BOLD}" "$R"; (( ab++ ))

  local bw2=$(( W/2 - 22 )); (( bw2 < 6 )) && bw2=6
  local tvk dmk admk bjp inc cpi cpim vck iuml dmdk mdmk pmk ammk spa nda declared others
  tvk=$(count_party  "$json" "TVK"); dmk=$(count_party  "$json" "DMK")
  admk=$(count_party "$json" "ADMK"); bjp=$(count_party "$json" "BJP")
  inc=$(count_party  "$json" "INC"); cpi=$(count_party  "$json" "CPI")
  cpim=$(count_party "$json" "CPI(M)"); vck=$(count_party "$json" "VCK")
  iuml=$(count_party "$json" "IUML"); dmdk=$(count_party "$json" "DMDK")
  mdmk=$(count_party "$json" "MDMK"); pmk=$(count_party "$json" "PMK")
  ammk=$(count_party "$json" "AMMK"); declared=$(total_decl "$json")
  spa=$(( dmk + inc + cpi + cpim + vck + iuml + dmdk + mdmk ))
  nda=$(( admk + bjp + pmk + ammk ))
  others=$(( declared - spa - nda - tvk ))
  (( others < 0 )) && others=0

  arow() {
    local lbl="$1" val=$2 col="$3"
    clear_row "$ab"
    printf '%b%b%-26s%b' "$col" "$BOLD" "$lbl" "$R"
    hbar "$val" "$TOTAL_SEATS" "$bw2" "$col"
    printf '%b%b %4d%b%b/%d%b\n' "$cWHITE" "$BOLD" "$val" "$R" "$cGRAY" "$TOTAL_SEATS" "$R"
    (( ab++ ))
  }
  arow "SPA/INDIA+ (DMK-led) " "$spa"   "$cGREEN"
  arow "AIADMK+/NDA          " "$nda"   "$cYELLOW"
  arow "TVK (solo)           " "$tvk"   "$cMAG"
  arow "Others / independents" "$others" "$cGRAY"

  # STATUS BAR
  local sb=$(( H - 1 ))
  clear_row "$sb"
  printf '%b' "${bgSTATUS}${cGRAY}"
  printf '%-'"$W"'s' ""
  at "$sb" 2
  local decl; decl=$(total_decl "$json")
  printf '%b  [q] Quit  [r] Refresh  [+/-] Interval  |  Declared: %d/%d%b' \
    "$cWHITE" "$decl" "$TOTAL_SEATS" "$R"
}

# CLEANUP
_cleanup() {
  printf '\033[?25h\033[0m'
  tput rmcup 2>/dev/null || true
  [[ -n "${OLD_STTY:-}" ]] && stty "$OLD_STTY" 2>/dev/null || stty sane 2>/dev/null || true
  echo ""; echo "Jai Hind! 🇮🇳"
}
trap _cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# MAIN
main() {
  tput smcup 2>/dev/null || true
  printf '\033[?25l'          # hide cursor
  clrscr

  OLD_STTY=$(stty -g 2>/dev/null || true)
  stty -echo -icanon min 0 time 0 2>/dev/null || true

  local json='{}' ts='-' last=0 key last_w last_h last_remain=-1
  last_w=$(cols); last_h=$(rows)

  while true; do
    local now; now=$(date +%s)
    local current_w current_h
    current_w=$(cols); current_h=$(rows)

    if (( current_w != last_w || current_h != last_h )); then
      clrscr
      last_w=$current_w
      last_h=$current_h
      last=0
    fi

    if (( now - last >= REFRESH )); then
      ts=$(date '+%H:%M:%S')
      json=$(fetch)
      last=$now
      draw "$json" "$ts"
    fi

    # countdown in corner
    local tick remain
    tick=$(date +%s)
    remain=$(( REFRESH - (tick - last) ))
    (( remain < 0 )) && remain=0
    if (( remain != last_remain )); then
      at "$(rows)" $(( $(cols) - 14 ))
      printf '%b next: %2ds %b' "${bgSTATUS}${cCYAN}" "$remain" "$R"
      last_remain=$remain
    fi

    key=''
    read -r -t 0.1 -n 1 key 2>/dev/null || true
    case "$key" in
      q|Q) exit 0 ;;
      r|R) last=0; last_remain=-1 ;;
      '+') (( REFRESH >  2 )) && (( REFRESH -= 2 )); last_remain=-1 ;;
      '-') (( REFRESH < 120)) && (( REFRESH += 2 )); last_remain=-1 ;;
    esac
  done
}

main
