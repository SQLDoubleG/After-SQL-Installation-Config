
if ( !(Powercfg -getactivescheme | ? { $_.Contains('High') }) ) {
    echo 'I''m not high performance';
    $GUID = (powercfg /l | ? { $_.Contains('High') -and $_.Contains('GUID')}).Split()[3];
    echo 'Changing Setting to ''High performance''';
    powercfg /setactive $GUID
    echo 'Done';
}
else{
    echo 'I''m high performance'
}


