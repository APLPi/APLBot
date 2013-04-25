⍝ Written by Morten Kromberg
⍝ First pass at DyaBot code to talk to Arduino based Robot running our I2C Arduino code.
⍝ http://www.dyalog.com


:Class DyaBot              
⍝ Object-oriented wrapper for the Dyalog Robot. Requires libi2c-com.so on the libpath.
⍝ Public Field "Speed" is a 2-element vector, range [¯1,1] (¯1=Full Astern, 1=Full Ahead)
⍝ First element controls right wheel, 2nd element left wheel
⍝ Example:
⍝
⍝     bot←⎕NEW DyaBot (240 255) ⍝ Right wheel a bit stronger than left
⍝     bot.Speed←.6 1 ⋄ ⎕DL 3 ⋄ bot.Speed←0 ⍝ Curve to right for 3 secs

    I2C_ADDRESS←4               ⍝ I2C address of the Arduino
    SpeedPins←5 9               ⍝ Analog Pins for Right & Left Speed
    DirectionPins←2 2⍴4 3 8 7   ⍝ Digital pins for Right & Left x Fwd & Back
    (Analog Digital)←⎕UCS 'AD'  ⍝ 'A' and 'D' command bytes

    :Field Public Speed←0 0
    :Field Private _range←255 255 ⍝ Right & Left speed range
    :Field Public Trace←1

    ∇ SetSpeed args;s;bytes;z
      :Implements Trigger Speed                
      :If 0=⍴⍴s←args.NewValue ⋄ s←2⍴s ⋄ :EndIf ⍝ Scalar Extension
      s←⌈s×(⍴s)⍴_range
      :If 2≠⍴s
      :AndIf 255∧.<|s
          ⎕SIGNAL 11
      :Else
     
          bytes←,Digital,(,(s<0)⌽DirectionPins),⍪1 0 1 0\s≠0 ⍝ Set all 4 direction pins to 1 or 0
          bytes←(,Analog,SpeedPins,⍪|s),bytes                ⍝ Write speeds
          :If Trace ⋄ ⎕←1↓('  '⎕R' '),',',⍕{z←⍵ ⋄ z[;1]←⎕UCS z[;1] ⋄ z}6 3⍴bytes ⋄ :EndIf
          z←WriteBytes I2C_ADDRESS bytes 0
      :EndIf
    ∇

    ∇ Make range;z
      :Access Public
      :Implements Constructor
     
      _range←range
      'OpenI2C'⎕NA'I libi2c-com.so|OpenI2C I I =I'
      'CloseI2C'⎕NA'I libi2c-com.so|CloseI2C =I'
      'WriteBytes'⎕NA'I libi2c-com.so|WriteBytes I <#U1[] =I'
      'ReadBytes'⎕NA'I libi2c-com.so|ReadBytes I <#U1[] =#U1[] =I'
      z←OpenI2C 1 0 0
    ∇

    ∇ UnMake;z
      :Implements Destructor
      z←CloseI2C 0
    ∇

:EndClass
