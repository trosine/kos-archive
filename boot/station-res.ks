// station-res.ks: automate resource transfers in and out of a station
// Since Element doesn't contain a :type suffix, I am basing this on
// Element:name where "station" or "module" indicate an element that's part of
// the station. All other elements are considered visiting ships.
// Ore comes into the station, fuels go out

// probably would be fine at load distance, but it has to wait until the ship
// is docked anyway
wait until ship:unpacked.


// when/on triggers are expected to complete within a physic tick
// instead, use wait until ..., then we can take as much time as we want
until false {
  local prev_elements is ship:elements:length.
  print "Waiting for (un)docking event (" + prev_elements + ")".
  wait until ship:elements:length <> prev_elements.
  if ship:elements:length > prev_elements {
    hudtext("Resource transfers starting", 5, 4, 20, green, true).
    resource_xfr().
    hudtext("Resource transfers complete", 5, 4, 20, green, true).
  }
}

function get_parts {
  parameter directions. // lex(resource => list(src, dst))

  // create basic structure: lex(section => lex(resource => parts))
  // where section is either "ship" or "station"
  local plex is lexicon().
  for section in directions:values[0] {
    set plex[section] to lexicon().
    for resource in directions:keys {
      set plex[section][resource] to list().
    }
  }

  // fill in all of the actual parts - since the structure has already been
  // initialized, the parts can just be added to the lists
  for element in ship:elements {
    local section is "ship".
    if element:name:contains("station") or element:name:contains("module") {
      set section to "station".
    }
    for resource in element:resources {
      if directions:haskey(resource:name) {
        for part in resource:parts {
          plex[section][resource:name]:add(part).
        }
      }
    }
  }
  return plex.
}

function resource_xfr {
  local inbound is list("ship", "station").
  local outbound is list("station", "ship").
  local directions is lexicon(
    "ore",            inbound,
    "liquidFuel",     outbound,
    "oxidizer",       outbound,
    "monopropellant", outbound
  ).
  local plex is get_parts(directions).

  print "Starting transfers...".
  local tx is lexicon().
  for res in directions:keys {
    local source is directions[res][0].
    local dest is directions[res][1].
    set tx[res] to make_transfer(res, plex[source][res], plex[dest][res]).
  }

  for res in tx:keys {
    local xfr is tx[res].
    // print "Waiting for " + xfr + " - " + xfr:status.
    wait until not xfr:active.
    print res + " transfer " + xfr:status + " (" + xfr:message + ")".
  }
  // print "All transfers complete".
}

function make_transfer {
  parameter res_name, source, dest.
  // if either source or dest is empty, the transfer fails gracefully
  local xfr is transferall(res_name, source, dest).
  xfr:active on.
  return xfr.
}
