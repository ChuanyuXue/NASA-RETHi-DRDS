## Agent Model in the **M**odular **C**oupled **V**irtual **T**est

This folder contains all files relating to the intervention agent model.

The files included in this folder is 
- `Sys6_agent.m`
    This file allows the definition of some high-level design variables and
    calls the wrapper module which initializes many structures essential for 
    agent system operation
- `InitAgentModel.m`
    This file instantiates variables and information regarding the operating 
    environment of the agent. Detailed information regarding each definition is 
    provided within the file.
- `LinearMemoryModule.m`
    This file defines the memory module of the intervention agent. This particular
    definition is that of a "Linear Memory Buffer", which is akin to an array.
- `AgentPlant.m`
    This module specifies the dynamics of the agent health states and the 
    interdependencies that the agent system would have with the sub-systems that
    it intervenes with.