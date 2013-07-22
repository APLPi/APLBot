:Class DyaBot : ArdCom             
⍝ Object-oriented wrapper for the Dyalog Robot.
⍝ Public Field "Speed" is a 2-element vector, range [¯100,100]
⍝ Public Field "SonarAngle" is the Sonar pointing direction [0,180]

⍝ First element controls right wheel, 2nd element left wheel
    <⍝ Example:
⍝
⍝     bot←⎕NEW DyaBot ((100 255) (100 255))  ⍝ Driving range 100-255
⍝     bot.Speed←60 100 ⋄ ⎕DL 3 ⋄ bot.Speed←0 ⍝ Curve to right for 3 secs   

⍝ Dependencies
⍝∇:require =/ArdCom

    ⎕IO←1                       ⍝ Index origin

    I2C_ADDRESS←4               ⍝ I2C address of the Arduino
    I2C_BUS←1                   ⍝ Which bus is I2C on          
        
    SonarInput←14               ⍝ Sonar ("a0")
    IRSensor←15                 ⍝ Analog Input ("a1")
    SonarServo←10               ⍝ Analog ("pwm") output
    SpeedPins←5 9               ⍝ Analog Pins for Right & Left Speed
    DirectionPins←2 2⍴4 3 8 7   ⍝ Digital pins for Right & Left x Fwd,Back

    Stopping←0                  ⍝ We are not stopping (used to stop monitor threads)

    :Field Public Speed←0 0
    :Field Public SonarAngle←90
    :Field Public IRange←¯1       ⍝ Infra Red Range
    :Field Public SRange←¯1       ⍝ Sonar Range
    :Field Private _range←255 255 ⍝ Right & Left speed range
    :Field Public Trace←0
    :Field Public Shared Testing←0            ⍝ Set to 1 to not actually issue I2C commands

    getnum←{2⊃⎕VFI ⍵}

    ∇ SetSpeed args;s;z;dp;direction;speeds
      :Implements Trigger Speed                
      :If 0=⍴⍴s←args.NewValue ⋄ s←2⍴s ⋄ :EndIf ⍝ Scalar Extension
      s←⌊(×s)×_lower+_range×(|s)÷100
      :If 2≠⍴s                                ⍝ Must have 2 elements
      :AndIf 255∧.<|s                         ⍝ And scaled result must be ≤255
          ⎕SIGNAL 11                          ⍝ Else signal a DOMAIN ERROR
      :Else
          dp←,(s<0)⌽DirectionPins             ⍝ Pin to be turned on in 1st column
          direction←,dp,⍪1 0 1 0\s≠0          ⍝ Set all direction pins
          speeds←,SpeedPins,⍪|s               ⍝ Set up speeds
          Send'W',direction,speeds
          ⍝:EndIf
      :EndIf
    ∇

    ∇ SetSonar args;s;z;dp;direction;speeds
      :Implements Trigger SonarAngle
      s←args.NewValue
      :If 1=⍴,s                               ⍝ Must have 1 elements
      :AndIf 180≥|s                           ⍝ And scaled result must be ≤255
          z←Send'W'SonarServo s
      :Else
          ⎕SIGNAL 11
      :EndIf
    ∇

    ∇ Stop
      :Access Public
      Stopping←1
      :While IRThread∊⎕TNUMS ⋄ ⎕DL 0.1 ⋄ :EndWhile
    ∇
    
    ∇ (rc err)←Update;pin;value;z;r;tries;ok;rcr
      :Access Public
     
      tries←0
      ok←0
     
      :Repeat
          :Trap 701
              :If 2=⍴z←ReadData
                  IRange←cmFromV(2⊃z)×5÷1200
                  SRange←1.27×1⊃z ⍝ vcc/512 per inch
                  ok←1
              :Else
                  ⎕DL 0.03
              :EndIf
          :Else
              tries+←1
              ⎕DL 0.1
              ResetSignals ⍝ // Clear signal handling
          :EndTrap
      :Until ok∨tries>10
     
      :If ~ok
          'UNABLE TO READ RANGES'⎕SIGNAL ok↓11
      :EndIf
    ∇

    ∇ Make ranges;z;count;err;rc;err1;rc1;txt;pins;values
      :Access Public
      :Implements Constructor :Base I2C_ADDRESS I2C_BUS
     
      :Select ⊃⍴ranges←,ranges
      :Case 0 ⋄ ranges←100 255
      :Case 2
      :Else ⋄ 'Invalid constructor argument'⎕SIGNAL 11
      :EndSelect
     
      :If 2=≡ranges
          _lower←1⊃¨ranges ⋄ _upper←2⊃¨ranges
      :Else ⋄ (_lower _upper)←ranges
      :EndIf
      _range←_upper-_lower
     
      pins←SonarServo'S' 0                  ⍝ 1 pwm Sonar Servo
      pins⍪←(SonarInput IRSensor),2 2⍴'a' 0 ⍝ 2 analog inputs
      pins⍪←SpeedPins,2 2⍴'A' 0             ⍝ 2 Analog Outputs
      pins⍪←(,DirectionPins),4 2⍴'D' 0      ⍝ 4 Digital Outputs
      Pins←pins ⍝ Set the ArdCom property
     
      count←0
      :If 2≠⍴values←ReadData
          ∘ ⍝ Arduino is not returning IR and Sonar values
      :EndIf
      (IRange SRange)←values
    ∇

    ∇ UnMake;z
      Speed←0
      SonarAngle←90
     
      :Implements Destructor     
    ∇
                                        
    ⍝ Voltage/Distance table from the SHARP GP2Y0A21YK0F data sheet
    IRvd←⍉11 2⍴80 0.4 50 0.6 40 0.7 30 0.9 25 1.1 20 1.3 15 1.6 10 2.3 8 2.7 7 3 6 3.2

    ∇ cm←cmFromV V;i;step
      :Access Public Shared
      :Select i←IRvd[2;]+.<V
      :Case 0 ⋄ cm←80
      :Case 2⊃⍴IRvd ⋄ cm←6
      :Else
          step←-/IRvd[;i+0 1]
          cm←IRvd[1;i]+step[1]×(V-IRvd[2;i])÷step[2]
      :EndSelect
    ∇
    
    ∇ ResetSignals
    ⍝ Reset signal handling: Workaround for issue with libi2c
      :Trap 11
          {⎕SIGNAL ⍵}11
      :EndTrap
    ∇

:EndClass