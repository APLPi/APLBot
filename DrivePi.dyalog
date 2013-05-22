:Namespace DrivePi
   ⍝ Interactive "game" to drive the C3Pi
   ⍝∇:require =/DyaBot

    (⎕IO ⎕ML)←1 1

    ⍝ Patterns
    fig8←5 3⍴60 60 2,10 100 3.5,100 100 1,100 10 2.5,60 60 2
    square←8 3⍴60 60 1.5, 60 ¯60 0.25 

    ∇ {bot}Play mat;i
    ⍝ "Play" each row of a 2-dimensional matrix
    ⍝ bot.Speed in 1st 2 cols, duration in 3rd col
     
      :If 9≠⎕NC'bot' ⋄ bot←⎕NEW #.DyaBot ⍬ ⋄ :EndIf ⍝ Create bot instance if not provided
     
      mat←(¯2↑1,⍴mat)⍴mat      ⍝ Make vector into a matrix
      :For i :In ⍳1↑⍴mat
          bot.Speed←mat[i;1 2] ⍝ Set speed to 1st 2 cols of mat
          ⎕DL mat[i;3]         ⍝ Delay
      :EndFor
      bot.Speed←0              ⍝ Always stop at the end
    ∇

    ∇ MonitorIR dummy
    ⍝ Partial implementation of 3rd & 1st laws of Robotics: http://en.wikipedia.org/wiki/Three_Laws_of_Robotics
    ⍝ 1. A robot may not injure a human being or, through inaction, allow a human being to come to harm.
    ⍝ 2. A robot must obey the orders given to it by human beings, except where such orders would conflict with the First Law.
    ⍝ 3. A robot must protect its own existence as long as such protection does not conflict with the First or Second Laws.
     
      :Repeat
          ⎕←'speed: ',⍕botspeed
          :If 150<⎕←distance←bot.IRange
              ⎕←'Proximity warning: ',⍕distance
          :AndIf (250<distance)∧0∨.<bot.Speed
              ⎕←'Auto-stop' ⋄ bot.Speed←botspeed←speed←0
          :EndIf
          ⎕DL 1
      :EndRepeat
    ∇

    ∇ Run;⎕RTL;char;speed;turning;bot;help;botspeed;newspeed;i;direction;target;diff;turns;paused;centre;distance;IRThread
     
      botspeed←speed←0        ⍝ Current speed:   0-100%
      bot←⎕NEW #.DyaBot((200 255)(90 140))
      IRThread←MonitorIR&0    ⍝ Start Proximity monitor
      ⍝ Numbers above calibrate range for Right and Left wheels
      bot.Trace←0
     
      ⎕RTL←1
      turns←{(⌽¨⌽1↓⍵),⍵}(1 1)(1.2 0.1)(0.4 ¯0.4)
      direction←centre←⌈0.5×⍴turns ⍝ That is where we are going
      paused←0
     
      help←'zx: left, right' 'cv: slower,faster' 'space: pause'
      help,←'48:   canned demos' 'q:    quit' '?:    repeat this information'
      help←'-'⍪(⍕⍪help)⍪'-'
      ⎕←help
     
      :Repeat
          :If 0≠char←⊃1 0 ⎕ARBIN''
              char←⎕UCS char
              :Select char
     
              :CaseList 'zx' ⍝ Left, Right
                  direction←1⌈(⍴turns)⌊direction+¯1*char='x'
     
              :CaseList 'cv' ⍝ Faster, Slower
                  speed←¯100⌈100⌊speed+10×¯1*char='c'
     
              :Case 's' ⍝ Straight
                  direction←1 1
     
              :Case ' '
                  paused←~paused
     
              :Case '.' ⍝ Carry on
     
              :CaseList '48' ⍝ Canned demos
                  bot Play⍎⎕←('48'⍳char)⊃'square' 'fig8'
                  speed←0 ⋄ direction←centre
     
              :Case '?' ⍝ help
                  ⎕←help
     
              :Else ⍝ all bad inputs: stop the robot
                  speed←0 ⋄ direction←1 1
                  ⎕←'(stopped)'
     
              :EndSelect
     
              botspeed←{(100⌊|⍵)××⍵}speed×direction⊃turns
     
              :If paused
                  ⎕←'paused: ',⍕botspeed
              :Else
                  bot.Speed←botspeed
              :EndIf
          :EndIf
     
      :Until char='q'
     
      bot.Stop
      ⎕TKILL IRThread
      ⎕←'Please play again soon!'
    ∇

:EndNamespace