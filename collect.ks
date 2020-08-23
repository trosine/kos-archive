// ship:partstagged("autocollect")
declare containers to ship:modulesnamed("ModuleScienceContainer").
declare experiments to ship:modulesnamed("ModuleScienceExperiment").

print "Collecting " + containers:length + " copies of " + experiments:length + " experiments.".
declare count to 1.
for container in containers {
  print "Running set " + count.
  for experiment in experiments {
    if experiment:hasdata {
      experiment:reset.
    }
    print "  " + experiment:part:title + " running...".
    experiment:deploy.
    wait until experiment:hasdata.
  }
  print "Collecting set " + count.
  container:doaction("Collect All", true).
  wait until not experiments[0]:hasdata.
  set count to count + 1.
}
print "Data collection complete".
