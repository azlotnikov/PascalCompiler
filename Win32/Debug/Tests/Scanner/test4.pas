 uses crt;
 var a:array [1..10] of integer;
     i,max,min,N,M: integer;
     s: string;
     f:text;
 begin
    clrscr;
    randomize;                        
    {$I-}
    s:='C:\Kirill11';
    Mkdir(s);
    assign(f, 'output.txt');
    rewrite(f);          
    max:=low(integer);
    min:=high(integer);
    for i:=1 to length(a) do begin
      a[i] := random(21)-10;
      if a[i]>max then max:=a[i];
      if a[i]<min then min:=a[i];
    end;

    writeln (f, 'Maximal el-nt = ', max);
    writeln (f, 'Minimal el-nt = ', min);
    
    for i:=1 to length(a) do begin
       writeln(f, 'a[',i,']= ', a[i]);
    end;
    readln;
end.

