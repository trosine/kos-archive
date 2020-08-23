core:doevent("open terminal").
set terminal:height to 17.
for x in range(terminal:height) print " ".
set mq to ship:messages.

runpath("0:/eva/functions.ks").

until false {
  wait until mq:length.
  global msg is mq:pop.
  print "Running " + msg:content[0].
  f[msg:content[0]]().
  print "done" at (20, terminal:height-2).
}
