:Class ArdCom              
⍝ Object-oriented wrapper for an Arduino running "ArdCom version 0.2 or later"
⍝∇:require =/I2C

    ⎕IO←⎕ML←1                   ⍝ Condition the environment
    _version←0.2
    :Field Public Version←¯1    ⍝ Version not checked yet

    :Field Public Trace←0       ⍝ Set to 1 to see all Sends      
    :Field Public Testing←0     ⍝ Set to 1 to not actually issue I2C commands
    _pins←0 3⍴0 ⍝ Internal state
    ⍝ Pins: [;1] Pin # (nb A0..A5 = 14-19)
    ⍝       [;2] Type: A,D,S = OUTPUT: Analog, Diginal, Sonar (PWM)
    ⍝                  a,d,p = INPUT: Analog, Digital, Pulse-driven Analog
    ⍝       [;3] "Info", only used for 'p': Pin used to send pulse

    :Property Pins
    :Access Public

        ∇ r←Get args
          r←_pins
        ∇
       
        ∇ Set args;pins;shape;p;n;z
          :If 2≠⍴shape←⍴pins←args.NewValue
          :OrIf ~(2⊃shape)∊2 3
              'Pins: [;1] Pin #, [;2] Type, [;3] Optional Extra Info'⎕SIGNAL 701
          :EndIf
          :If 2=⊃shape ⋄ pins←pins,0 ⋄ :EndIf ⍝ Add optional info if missing
          p←pins
          z←Reset
          :While 0≠1↑⍴p
              Send'S',,(n←4⌊1↑⍴p)↑p
              p←n↓p
          :EndWhile
          _pins←pins
          {}Identify ⍝ Forces verification of pins
        ∇

    :EndProperty

    getnum←{2⊃⎕VFI ⍵}

    ∇ {r}←Send bytes;i
      :Access Public
     ⍝ I2C.WriteBytes, auto-coverting chars to ints and adding command length
     
      bytes←,bytes
      :Select ⎕DR bytes
      :Case 80 ⋄ bytes←⎕UCS bytes
      :Case 326 ⋄ bytes[i]←⎕UCS bytes[i←{⍵/⍳⍴⍵}80=⎕DR¨bytes]
      :CaseList 83 11 ⍝ OK
      :Else
          ⎕SIGNAL 11
      :EndSelect
      bytes←(⍴bytes),bytes
      :If Trace∨Testing
          ⎕←'ArdCom.Send: ',⍕bytes
      :EndIf
     
      :If 0≠1⊃r←#.I2C.WriteBytes I2C_ADDRESS bytes 255
      :AndIf 0≠1⊃r←#.I2C.WriteBytes I2C_ADDRESS bytes 255 ⍝ Retry once
          ('I2C.WriteBytes failed: ',⍕r)⎕SIGNAL 701
      :EndIf
      ⎕DL 0.03
    ∇

    ∇ r←ReadBytes;z;log;l
      :Access Public    
     
      log←''
      :Repeat
          :If 0≠1⊃z←#.I2C.ReadBytes I2C_ADDRESS(32⍴255)255
              ('I2C.ReadBytes failed: ',⍕z)⎕SIGNAL 701
          :EndIf
          :If l←254=1↑r←2⊃z ⋄ log,←⎕UCS 1↓r ⋄ :EndIf ⍝ Diagnostic output
      :Until ~l
      :If 0≠⍴log ⋄ ⎕←log ⋄ :EndIf
    ∇

    ∇ r←ReadChar;z
      :Access Public                     
      r←⎕UCS ReadBytes
    ∇

    ∇ r←ReadData;z
      :Access Public                     
      :If 0≠2|⍴r←¯1↓ReadBytes ⋄ ∘ ⋄ :EndIf ⍝ Not returning pairs of bytes!
      r←256⊥⍉((0.5×⍴r),2)⍴r
    ∇
    
    ∇ Make args;z;data;ver;r
      :Access Public
      :Implements Constructor
     
      ⍝ ResetSignals
      (I2C_ADDRESS I2C_BUS)←2↑args,(⍴,args)↓4 1
      :If 0=⎕NC'#.I2C.Close'
          :If 0≠z←#.I2C.Init ⍬
              ('I2C.Init failed: ',⍕z)⎕SIGNAL 701
          :EndIf
      :EndIf
     
      :If 0≠1⊃z←#.I2C.Open I2C_BUS 0 0
          ('I2C.Open failed: ',⍕z)⎕SIGNAL 701
      :EndIf
     
      {}⎕DL 0.1 ⍝ Stabilize
      r←Reset
    ∇
    
    ∇ {r}←Reset
      :Access Public
      _pins←0 3⍴0
      r←Send'R'
      ReadChar
      r←Identify
    ∇

    ∇ r←Identify;ver;pins;reported;data;expected
      :Access Public
     
      Send'I'
      data←ReadChar
     
      :If ~∧/(ver←2↑data)∊⎕D
          ('I did not return version#: ',data)⎕SIGNAL 701
      :EndIf
     
     
      Version←0.1×10⊥¯1+⎕D⍳ver
      :If Version≠_version
          ('Arduino is running v',(⍕Version),', v',(⍕_version),' is required')⎕SIGNAL 701
      :EndIf
     
      :If 2<⍴data ⍝ Some pins are set up
          pins←({((⌈0.5×⍴⍵),2)⍴⍵}2↓data),0
          pins[;1]←⎕UCS pins[;1]
      :Else
          pins←0 3⍴0
      :EndIf
     
      reported←↓pins[;1 2] ⋄ expected←↓_pins[;1 2]
      :If ~∧/(reported∊expected),expected∊reported
          ⎕←2 2⍴'reported' 'expected'reported expected
          ∘ ⍝ Internal error: Mismatch between reported and expected pins
      :EndIf
     
      r←Version _pins
    ∇

    ∇ UnMake;z
      :Implements Destructor
     
      ⍝:If ~Testing
      ⍝    z←#.I2C.Close 0
      ⍝:EndIf
    ∇
    
    ∇ ResetSignals
    ⍝ Reset signal handling: Workaround for issue with libi2c
      :Trap 11
          {⎕SIGNAL ⍵}11
      :EndTrap
    ∇

:EndClass
