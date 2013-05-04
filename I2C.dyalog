:Namespace I2C
    ⍝ Converted from the quick2wire-python-api
    ⍝ For more information see https://github.com/quick2wire/quick2wire-python-api

    ∇ Test;z
      ⍝ ToDo: Check return codes
     
      I2C_BUS←1           ⍝ I2C bus on port #1 on both model A and B unless you have an early version of the Pi
      ADDRESS←4           ⍝ I2C address of the C3Pi's Arduino
     
      z←Init ⍬            ⍝ Load the Shared Object
      z←Open I2C_BUS 0 0  ⍝ Open bus
      z←WriteBytes #.T1←ADDRESS(68 3 1 68 4 0 68 8 1 68 7 0 65 5 255 65 9 255)0 ⍝ Spin Right
      z←⎕DL 2             ⍝ Delay two seconds
      z←WriteBytes ADDRESS(68 4 0 68 3 0 68 8 0 68 7 0 65 5 0 65 9 0)0     ⍝ Stop
      z←Close 0
    ∇

    ∇ r←Init dummy
      'Open'⎕NA'I libi2c-com.so|OpenI2C I I =I'                 ⍝ bus, extra_open_flags, err
      'Close'⎕NA'I libi2c-com.so|CloseI2C =I'                   ⍝ err
      'WriteBytes'⎕NA'I libi2c-com.so|WriteBytes I <#U1[] =I'      ⍝ address, bytes[], err
      'ReadBytes'⎕NA'I libi2c-com.so|ReadBytes I <#U1[] =#U1[] =I' ⍝ address, inbytes[], outbytes[], err
      r←0
    ∇

:EndNamespace