:Namespace mpu9150
⍝ Dependencies
⍝∇:require =/RTIMULib
⍝ Morten was here

    Degrees←{180×⍵÷○1}                                                                                                                                                                             
    Direction←{w←360|⍵ ⋄ w>180:w-360 ⋄ w}                                                                                                                                                          

    ∇ r←Compass
     ⍝ Return a compass heading between [0,360>
      r←360|180+Degrees 3⊃#.RTIMULib.getData.fusionPose
    ∇

    ∇ r←CompassJay
     ⍝ Return a compass heading between [0,360>
     ⍝ Project
      r←360-180+Degrees 12○1 0J1 0+.×#.RTIMULib.getData.compass
    ∇

    ∇ (heading gyro)←HeadingRotation
    ⍝ Return z-axis compass heading (deg) and current rotation (deg/sec)
      (heading gyro)←Degrees 3⊃¨#.RTIMULib.getData.(fusionPose gyro)
      gyro←gyro×0.2<|gyro     ⍝ Remove dead zone noise
      heading←360|180+heading ⍝ Board is back-to-front on the bot
    ∇
   
    ∇ {log}←Heading n;start;step0;too_far;max_steps;step_from;initial_turn;d;min_throttle;deltas;direction;max_throttle;prev_rotation;acceleration_rqd;rotation_change;rt;yet_to_turn;throttle;heading;rotation;rotation_tgt;slow_gap;min;max;delta;t;force;done;steps;speed
    ⍝ Turn DyaBot <bot> to heading n degrees in easy steps
     
      steps←1 ⋄ max_steps←200
      log←max_steps 7⍴0
      rotation_tgt←100   ⍝ Degrees/sec for long range moves
      slow_gap←30        ⍝ Slow down if closer than this
      step_from←10       ⍝ Step mode from 5 degrees
      throttle←0         ⍝ Current throttle setting
      min_throttle←¯1    ⍝ Required to move at all (¯1=unknown)
      max_throttle←20    ⍝ Don't give more gas than this
      prev_rotation←0    ⍝ Last measured rotation
      start←⎕AI[3]       ⍝ Starting time
     
      :Trap 1000         ⍝ Allow user interrupt to end rotation
          initial_turn←Direction n-1⊃HeadingRotation
          :Repeat
              (heading rotation)←HeadingRotation
              rotation_change←rotation-prev_rotation
              prev_rotation←rotation
     
              yet_to_turn←|delta←Direction n-heading ⍝ how many degrees yet to turn
              direction←×delta                       ⍝ 1=right, ¯1=left
              done←(1>yet_to_turn)∧rotation=0        ⍝ are we there already!?
     
              :If (min_throttle=¯1)∧10<|rotation     ⍝ First significant move?
                  min_throttle←throttle              ⍝ Throttle required to move
              :EndIf
     
              :If too_far←direction≠×initial_turn  ⍝ If we came too far, or are
              :OrIf step_from>yet_to_turn          ⍝   close enough for step mode?
                  #.bot.Brake                      ⍝ Brake and
                  :Repeat ⋄ ⎕DL 0.1 ⋄ :Until 0=2⊃HeadingRotation ⍝ come to a stop
     
                  initial_turn←Direction n-⊃HeadingRotation ⍝ Reset initial turn
                  :If step_from>|initial_turn               ⍝ Close enough to step?
                      speed←(|min_throttle)×¯1 1××initial_turn
                      step0←steps
                      :Repeat
                          #.bot.Speed←speed ⋄ #.bot.Speed←0
                          (heading rotation)←HeadingRotation
                          log[steps;]←7↑(⎕AI[3]-start),heading,rotation,0 0,speed
                          steps←(≢log)⌊steps+1
                          :If 10<steps-step0 ⍝ Did not get there in 10 steps?
                              speed←2×speed ⋄ step0←steps ⍝ Try a bit harder
                          :EndIf
                      :Until 1>|delta←Direction n-heading ⍝ within 1 degree
                      :OrIf (×delta)≠×initial_turn        ⍝ or gone too far
                      done←1
                  :Else
                      log[steps;]←7↑(⎕AI[3]-start),HeadingRotation,998+too_far
                  :EndIf
                  throttle←prev_rotation←0
     
              :Else                     ⍝ we are rotating in the right direction
                  rt←rotation_tgt×(yet_to_turn⌊slow_gap)÷slow_gap ⍝ adjust target speed when close
                  acceleration_rqd←(rt×direction)-rotation  ⍝ How much acceleration is needed?
     
                  :If (|rt)<|rotation ⋄ throttle←0 ⍝ too fast:idle
                  :ElseIf ~((×rotation_change)∊0,×direction)∧10<|rotation_change
                      throttle←(|min_throttle)⌈max_throttle⌊throttle+1 ⍝ speed up
                  :EndIf
     
                  speed←throttle×¯1 1×direction×~done
                  #.bot.Speed←speed
     
                  log[steps;]←(⎕AI[3]-start),heading,rotation,acceleration_rqd,rotation_change,speed
                  steps+←1
              :EndIf
     
          :Until done∨steps>max_steps
      :Else
          ⎕←'Interrupt'
      :EndTrap
     
      #.bot.Brake   ⍝ No matter what happened above
      log←steps↑log ⍝ Drop unused log data
    ∇

:EndNamespace