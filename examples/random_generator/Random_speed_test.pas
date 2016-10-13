program Random_speed_test;
uses sysUtils, CastleRandom;

{and test everything}

var seed:longint = 233489679;
function Raw(N: LongInt): LongInt;
begin
  seed := ((seed xor (seed shl 1)) xor ((seed xor (seed shl 1)) shr 15)) xor
         (((seed xor (seed shl 1)) xor ((seed xor (seed shl 1)) shr 15)) shl 4);
  if N>1 then
    result := LongInt((int64(LongWord(seed))*N) shr 32)
  else
    result := 0
end;

const N_of_tests = 300000000;
var i: integer;
    RND: TCastleRandom;
    sum: double;
    sumint: integer;
    BiasInt,BiasFloat: integer;
    T: TDateTime;

begin
  RND := TCastleRandom.create;

  sleep(1); //wait until the routine starts up... else we'll get slow-dowsn at first test.

  sum := 0;
  T := now;
  for i := 1 to N_of_tests do
    sum += 0.5;
  biasFloat:=round((now-T)*24*60*60*1000);
  sumint := 0;
  T := now;
  for i := 1 to N_of_tests do
    sumint += 1;
  biasInt:=round((now-T)*24*60*60*1000);
  writeln('bias ineger = ',biasInt,' float = ',biasFloat);

  sum := 0;
  T := now;
  for i := 1 to N_of_tests do
    sum += random;
  writeln('SysUtils float random   t = ',round((now-T)*24*60*60*1000)-BiasFloat,' ms average = ',sum/N_of_tests);

  sum := 0;
  T := now;
  for i := 1 to N_of_tests do
    sum += RND.random;
  writeln('Castle float random     t = ',round((now-T)*24*60*60*1000)-BiasFloat,' ms average = ',sum/N_of_tests);

  sumint := 0;
  T := now;
  for i := 1 to N_of_tests do
    sumint += random(2);
  writeln('SysUtils integer random t = ',round((now-T)*24*60*60*1000)-BiasInt,' ms average = ',sumint/N_of_tests);

  sumint := 0;
  T := now;
  for i := 1 to N_of_tests do
    sumint += RND.random(2);
  writeln('Castle integer random   t = ',round((now-T)*24*60*60*1000)-BiasInt,' ms average = ',sumint/N_of_tests);

  sumint := 0;
  T := now;
  for i := 1 to N_of_tests do
    sumint += raw(2);
  writeln('Raw integer Xorshift    t = ',round((now-T)*24*60*60*1000)-BiasInt,' ms average = ',sumint/N_of_tests);


  sumint := 0;
  T := now;
  for i := 1 to N_of_tests do if RND.random(2)=0 then inc(sumint);
  writeln('integer t = ',round((now-T)*24*60*60*1000)-BiasInt,' ms average = ',sumint/N_of_tests);
  sumint := 0;
  T := now;
  for i := 1 to N_of_tests do if RND.randomBoolean then inc(sumint);
  writeln('random2 t = ',round((now-T)*24*60*60*1000)-BiasInt,' ms average = ',sumint/N_of_tests);

  sumint := 0;
  T := now;
  for i := 1 to N_of_tests do Sumint += RND.random(3)-1;
  writeln('integer t = ',round((now-T)*24*60*60*1000)-BiasInt,' ms average = ',sumint/N_of_tests);
  sumint := 0;
  T := now;
  for i := 1 to N_of_tests do sumint += RND.randomSign;
  writeln('random3 t = ',round((now-T)*24*60*60*1000)-BiasInt,' ms average = ',sumint/N_of_tests);


end.
