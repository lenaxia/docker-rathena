#!/bin/bash
# apply-bot-patches.sh — patches rAthena source for bot load-testing stability.
# Run from /opt/rAthena. Exits non-zero on any patch failure.
set -euo pipefail

# Patch 1: status_get_hpbonus — null-check sd after map_id2sd.
# Race: char-server register sync arrives before session is initialized →
# sd is null → SIGSEGV on sd->bonus.hp dereference.
# Uses sed with a\ to append the null check after the matched line.
sed -i '/map_session_data \*sd = map_id2sd(bl->id);/a\\t\t\tif( sd == nullptr ){ ShowError("status_get_hpbonus: sd is null for bl->id=%d\\n", bl->id); return 0; }' src/map/status.cpp
if ! grep -q 'sd is null' src/map/status.cpp; then
    echo 'FATAL: patch 1 (status_get_hpbonus null-check) did not apply — upstream source has changed' >&2
    exit 1
fi

# Patch 2: status_calc_pc_sub — skip recalc if session not initialized.
# Guards against the same race via a different code path.
sed -i '/if (++calculating > 10) \/\/ Too many recursive calls!/{n;s/return -1;/return -1; if( !(opt\&SCO_FIRST) \&\& sd->base_status.max_hp == 0 ){ --calculating; return -1; }/}' src/map/status.cpp
if ! grep -q 'base_status.max_hp == 0' src/map/status.cpp; then
    echo 'FATAL: patch 2 (status_calc_pc_sub init guard) did not apply — upstream source has changed' >&2
    exit 1
fi

# Patch 3: pc_setparam SP_PCDIECOUNTER — guard status_calc_pc call.
# Only Super Novice characters with die_counter==1 trigger this path.
# Note: upstream uses MAPID_SECONDMASK (not MAPID_UPPERMASK) at this site.
sed -i 's/if (!sd->state.connect_new \&\& sd->die_counter == 1 \&\& (sd->class_\&MAPID_SECONDMASK) == MAPID_SUPER_NOVICE)/if (!sd->state.connect_new \&\& sd->die_counter == 1 \&\& (sd->class_\&MAPID_SECONDMASK) == MAPID_SUPER_NOVICE \&\& sd->bonus.hp != 0)/' src/map/pc.cpp
if ! grep -q 'sd->bonus.hp != 0' src/map/pc.cpp; then
    echo 'FATAL: patch 3 (pc_setparam PCDIECOUNTER guard) did not apply — upstream source has changed' >&2
    exit 1
fi

echo 'All 3 patches applied and verified.'
