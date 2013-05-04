:Class DyaBot              
⍝ Object-oriented wrapper for the Dyalog Robot
⍝ Public Field "Speed" is a 2-element vector, range [¯100,100] (¯100=Full Astern, 100=Full Ahead)
⍝ First element controls right wheel, 2nd element left wheel
    <⍝ Example:
⍝
⍝     bot←⎕NEW DyaBot ((100 255) (100 255))  ⍝ Driving range 100-255
⍝     bot.Speed←60 100 ⋄ ⎕DL 3 ⋄ bot.Speed←0 ⍝ Curve to right for 3 secs   

    ⍝ Dependencies
    ⍝∇:require =/I2C

    (⎕IO ⎕ML)←1 0

    I2C_ADDRESS←4               ⍝ I2C address of the Arduino
    I2C_BUS←1                   ⍝ Which bus is I2C on

    SpeedPins←5 9               ⍝ Analog Pins for Right & Left Speed
    DirectionPins←2 2⍴4 3 8 7   ⍝ Digital pins for Right & Left x Fwd,Back
    (Analog Digital)←⎕UCS 'AD'  ⍝ A and D command values

    :Field Public Speed←0 0
    :Field Public Trace←1             ⍝ Controls whether diagnostic output is displayed for each write
    :Field Public Shared Testing←0    ⍝ Set to 1 to not actually issue I2C commands

    ∇ SetSpeed args;s;z;dp;direction;speeds
      :Implements Trigger Speed               ⍝ Called when Speed field is set
      :If 0=⍴⍴s←args.NewValue ⋄ s←2⍴s ⋄ :EndIf ⍝ Allow a single number
      s←⌊(×s)×_lower+_range×(|s)÷100          ⍝ map 0 to _lower and 100 to _upper
      :If 2≠⍴s                                ⍝ Must have 2 elements
      :AndIf 255∧.<|s                         ⍝ And scaled result must be ≤255
          ⎕SIGNAL 11                          ⍝ Else signal a DOMAIN ERROR
      :Else
          dp←,(s<0)⌽DirectionPins             ⍝ Pin to be turned on in 1st column
          direction←,Digital,dp,⍪1 0 1 0\s≠0  ⍝ Set all direction pins
          speeds←,Analog,SpeedPins,⍪|s        ⍝ Set up speeds
          :If Trace ⋄ ⎕←1↓('  '⎕R' '),',',⍕{z←⍵ ⋄ z[;1]←⎕UCS z[;1] ⋄ z}6 3⍴direction,speeds ⋄ :EndIf
          :If ~Testing
              z←#.I2C.WriteBytes #.T2←I2C_ADDRESS(direction,speeds)0
          :EndIf
      :EndIf
    ∇

    ∇ Make ranges;z
      :Access Public
      :Implements Constructor
     
      :Select ⊃⍴ranges←,ranges
      :Case 0 ⋄ ranges←100 255
      :Case 2
      :Else ⋄ 'Invalid constructor argument'⎕SIGNAL 11
      :EndSelect
     
      :If 2=≡ranges   ⍝ (right-lower right-upper) (left-lower left-upper)
          _lower←1⊃¨ranges ⋄ _upper←2⊃¨ranges
      :Else ⋄ (_lower _upper)←ranges ⍝ (lower upper) - same for left and right
      :EndIf
      _range←_upper-_lower
     
      :If ~Testing
          z←#.I2C.Init ⍬
          z←#.I2C.Open 1 0 0
      :EndIf
    ∇

    ∇ UnMake;z
      :Implements Destructor
      :If (~Testing)∧1=⍴⎕INSTANCES⊃⊃⎕CLASS ⎕THIS
          z←#.I2C.Close 0 ⍝ Only close if we are the last instance
      :EndIf
    ∇

:EndClass