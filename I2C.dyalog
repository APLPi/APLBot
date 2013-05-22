:Namespace I2C
    ⍝ Converted from the quick2wire-python-api
    ⍝ For more information see https://github.com/quick2wire/quick2wire-python-api

    ∇ r←Init dummy
      'Open'⎕NA'I libi2c-com.so|OpenI2C I I =I'                 ⍝ bus, extra_open_flags, err
      'Close'⎕NA'I libi2c-com.so|CloseI2C =I'                   ⍝ err
      'WriteBytes'⎕NA'I libi2c-com.so|WriteBytes I <#U1[] =I'   ⍝ address, bytes[], err
      'ReadBytes'⎕NA'I libi2c-com.so|ReadBytes I >#U1[256] =I'  ⍝ address, bytes[], err
      'WriteChar'⎕NA'I libi2c-com.so|WriteBytes I <#C =I'       ⍝ address, bytes[], err
      'ReadChar'⎕NA'I libi2c-com.so|ReadBytes I >#C =I'         ⍝ address, bytes[], err
      r←0
    ∇

:EndNamespace
