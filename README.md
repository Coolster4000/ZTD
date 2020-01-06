This is a prototype of a Tower Defense game, made as practice during 100 Days of Code (Day 4!). Bloons TD5 is basically the greatest Tower Defense game of all time (possibly the greatest game of all time), so expect a lot of features to be similar. There is no goal. The aim is not to be a distributed game. I like the idea of procedurally generated levels to distinguish this game from Bloons but I'm not really good with math so who knows if I'll go down that route.
For now, the code is structured like this:
The things to destroy are "agents". "Towers" destroy agents by shooting "darts". Agents follow a path that has random dips and spikes at the moment. The information used to make an agent is stored in the `protos` table. Use newAgent(line[1], line[2], protos[1]) to make an agent at x, y with the prototype stored as the first value in the protos table. line[1], line[2] are the x/y vals of the start of the path.
Eventually I'd like to work on the system used to spawn premade waves, currently sitting useless in the waves table.