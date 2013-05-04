:Namespace DrivePi
   ⍝ Interactive "game" to drive the C3Pi
   ⍝∇:require =/DyaBot
       
    (⎕IO ⎕ML)←1 0

    ⍝ Canned demos - suitable arguments to the "Play" function
    fig8←5 3⍴60 60 2,10 100 3.5,100 100 1,100 10 2.5,60 60 2
    square←8 3⍴60 60 1.5, 60 ¯60 0.25 

    ∇ Run;⎕RTL;char;speed;turning;bot;help;botspeed;newspeed;i;direction;target;diff;turns;paused;centre
     
      bot←⎕NEW #.DyaBot((115 255)(100 210))
      ⍝ Numbers above calibrate range for Right and Left wheels
      bot.Trace←0
     
      ⎕RTL←1
      speed←0        ⍝ Current speed:   0-100%
      turns←{(⌽¨⌽1↓⍵),⍵}(1 1)(1 0.2)(0.7 0)
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
     
              :CaseList 'cv'   ⍝ Faster, Slower
                  speed←¯100⌈100⌊speed+25×¯1*char='c'
     
              :Case ' '
                  paused←~paused
     
              :CaseList '48' ⍝ Canned demos
                  bot Play⍎⎕←('48'⍳char)⊃'square' 'fig8'
                  speed←0 ⋄ direction←centre
     
              :Case '?' ⍝ help
                  ⎕←help
     
              :Else ⍝ all bad inputs: stop the robot
                  speed←0
                  ⎕←'(stopped)'
     
              :EndSelect
     
              botspeed←{(100⌊|⍵)××⍵}speed×direction⊃turns
     
              :If paused
                  ⎕←'paused: ',⍕botspeed ⍝ Show what speed WOULD be if not paused
              :Else
                  bot.Speed←botspeed
              :EndIf
          :EndIf
     
      :Until char='q'
    ∇

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
    
:EndNamespace