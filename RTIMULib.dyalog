:Namespace RTIMULib

    ∇ Init;lib;path
     ⍝ Initialise the shared library
     ⍝ Path is where ws was loaded from or pwd if unsaved
     
      path←{'CLEAR WS'≡⍵:⎕SH'pwd' ⋄ (1-⌊/(⌽⍵)⍳'\/')↓⍵}⎕WSID
      lib←path,'libRTIMULib.so'
      '_getData'⎕NA'I ',lib,'|getData >{U8 I1 I1[3] F4[3] I1 I1[3] F4[4] I1 I1[3] F4[3] I1 I1[3] F4[3] I1 I1[3] F4[3] I1 I1[3] F4 I1 I1[3] F4 I1 I1[3] F4}'
      ⎕NA lib,'|setCalibrationMode I'
    ∇
 
    ∇ Unload
     ⍝ Unload the shared library
      ⎕EX'_getData'
    ∇

    ∇ r←getData;t
      (r t)←_getData 0
      ('RTIMULib.getData failed: ',,⍕r t)⎕SIGNAL(r≠1)/11
      t←(25⍴1 1 0)/t
      r←#.⎕NS''
      r.(timestamp fusionPoseValid fusionPose fusionQPoseValid fusionQPose gyroValid gyro accelValid accel compassValid compass pressureValid pressure temperatureValid temperature humidityValid humidity)←t
    ∇

:EndNamespace