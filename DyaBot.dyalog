:Class DyaBot              
⍝ Object-oriented wrapper for the Dyalog Robot
⍝ Public Field "Speed" is a 2-element vector, range [¯1,1] (¯1=Full Astern, 1=Full Ahead)
⍝ First element controls right wheel, 2nd element left wheel
    <⍝ Example:
⍝
⍝     bot←⎕NEW DyaBot ((100 255) (100 255))  ⍝ Driving range 100-255
⍝     bot.Speed←60 100 ⋄ ⎕DL 3 ⋄ bot.Speed←0 ⍝ Curve to right for 3 secs   

    ⍝∇:require =/I2C

    (⎕IO ⎕ML)←1                 ⍝ Index origin

    I2C_ADDRESS←4               ⍝ I2C address of the Arduino
    I2C_BUS←1                   ⍝ Which bus is I2C on          
        
    IRSensor←0                  ⍝ Analog Input
    SpeedPins←5 9               ⍝ Analog Pins for Right & Left Speed
    DirectionPins←2 2⍴4 3 8 7   ⍝ Digital pins for Right & Left x Fwd,Back
    (Analog Digital AnalogRead)←⎕UCS 'ADa'  ⍝ A and D command values

    Stopping←0                  ⍝ We are not stopping (used to stop monitor threads)

    :Field Public Speed←0 0
    :Field Public IRange←¯1 
    :Field Private _range←255 255 ⍝ Right & Left speed range
    :Field Public Trace←1
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
          direction←,Digital,dp,⍪1 0 1 0\s≠0  ⍝ Set all direction pins
          speeds←,Analog,SpeedPins,⍪|s        ⍝ Set up speeds
          :If Trace ⋄ ⎕←1↓('  '⎕R' '),',',⍕{z←⍵ ⋄ z[;1]←⎕UCS z[;1] ⋄ z}6 3⍴direction,speeds ⋄ :EndIf
          ⍝:If ~Testing
          z←#.I2C.WriteBytes I2C_ADDRESS(direction,speeds)0
          ⍝:EndIf
      :EndIf
    ∇

    ∇ Stop
      :Access Public
      Stopping←1
      :While IRThread∊⎕TNUMS ⋄ ⎕DL 0.1 ⋄ :EndWhile
    ∇
    
    ∇ (rc err)←UpdateIRange;pin;value;z;r
      :Access Public
     
      (rc r err)←#.I2C.ReadChar I2C_ADDRESS 255 255
      :If rc=0
      :AndIf 2=⍴z←getnum('a(\d+):(\d+);?'⎕R'\1 \2')r
          (pin value)←z
      :AndIf pin=IRSensor
          IRange←cmFromV z←value×5÷1200
          err←value
      :Else
          IRange←¯1
      :EndIf
    ∇

    ∇ MonitorIR dummy;err;rc
      ⍝ Keep the IRange field up-to-date
      :Repeat
          (rc err)←UpdateIRange
          :If rc=0 ⋄ ⎕DL 0.1
          :Else ⋄ ⎕DL 0.01
          :EndIf
          ⎕DL 1
      :Until Stopping
    ∇

    ∇ Make ranges;z;count;err;rc;err1;rc1;txt
      :Access Public
      :Implements Constructor
     
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
     
      :If ~Testing
          z←#.I2C.Init ⍬
          z←#.I2C.Open 1 0 0
      :EndIf
     
      count←0
      :Repeat
          (rc1 err1)←#.I2C.WriteBytes I2C_ADDRESS(AnalogRead IRSensor 0)0 ⋄ ⎕DL 0.03
          (rc txt err)←#.I2C.ReadChar I2C_ADDRESS 255 255
          count←count+1
          :If count>5
              ('Unable to initialise IR sensor: ',⍕rc err)⎕SIGNAL 11
          :EndIf
      :Until (rc=0)∧rc1=0
     
      ⎕←#.I2C.ReadChar I2C_ADDRESS 255 255
      ⎕←'IR Monitor ',txt,', Thread: ',⍕IRThread←MonitorIR&0
    ∇

    ∇ UnMake;z
      :Implements Destructor
     
      :If (~Testing)∧1=⍴⎕INSTANCES⊃⊃⎕CLASS ⎕THIS
          z←#.I2C.Close 0
      :EndIf
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

:EndClass