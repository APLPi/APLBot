:Namespace Spike
	⍝ Converted from the quick2wire-python-api by Liam Flanagan
	⍝ For more information see https://github.com/quick2wire/quick2wire-python-api
	
	⍝ Dependencies
	⍝∇:require =/I2C
	
	I2C_BUS←1 ⍝ The bus that the I2C is on, on the Pi model A this is 0, on the model B this is 1.
	ADDRESS←4 ⍝ This is the address of the arduino
	
	∇ ret←main;⎕IO;ret;funret;funerr
		ret←0
		
		funret funerr ← #.I2C.OpenI2C I2C_BUS 0 0
		:If funret≢0
			ret←funerr
			→clean
		:EndIf
		
		GetInput
		
		clean:         ⍝ Tidy Up
		funret funerr ← #.I2C.CloseI2C 0
	∇
	
	∇ GetInput;⎕RTL
		⎕RTL←1
		
		'Started'
		input_loop:
		char←⊃1 0 ⎕ARBIN ''
		
		:Select char
			:Case 113	⍝ 'q'
			→input_loop_end
			:Else
			funret funerr ← #.I2C.WriteBytes ADDRESS (,char) 0
		:EndSelect
		
		→input_loop
		
		input_loop_end:
		'Exited'
	∇	
	
:EndNamespace
