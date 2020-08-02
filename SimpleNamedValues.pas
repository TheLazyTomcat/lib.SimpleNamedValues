{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Simple Named Values

    This library provides a class that implements a list of name-value pairs.

    It is intended for passing data to objects or functions when the type and
    amount of data cannot be known at compile-time. It is similar to passing
    an array of variants, but is more structured and reliable, as the data do
    not need to be ordered.
    It should NOT be used for long-term data storage or when the data are
    frequently accessed (access is not optimized for speed).

    Only some basic types are implemented, but by using typecasting and dynamic
    memory allocation, practically any data can be stored.

    Typical use should be following:

      - create an instance of TSimpleNamedValues
      - fill it with required data
      - pass it to function/class that requires this data
      - the function/class should copy the passed data to a local storage
        and/or use them as needed
      - upon return from the function/method, free the instance and with it the
        data

  Version 1.0 (2020-07-28)

  Last change 2020-08-02

  ©2020 František Milt

  Contacts:
    František Milt: frantisek.milt@gmail.com

  Support:
    If you find this code useful, please consider supporting its author(s) by
    making a small donation using the following link(s):

      https://www.paypal.me/FMilt

  Changelog:
    For detailed changelog and history please refer to this git repository:

      github.com/TheLazyTomcat/Lib.SimpleNamedValues

  Dependencies:
    AuxTypes   - github.com/TheLazyTomcat/Lib.AuxTypes
    AuxClasses - github.com/TheLazyTomcat/Lib.AuxClasses

===============================================================================}
unit SimpleNamedValues;

interface

{$IFDEF FPC}
  {$MODE ObjFPC}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}
{$H+}

uses
  SysUtils,
  AuxClasses;

type
  ESNVException = class(Exception);

  ESNVIndexOutOfBounds  = class(ESNVException);
  ESNVInvalidValue      = class(ESNVException);
  ESNVUnknownNamedValue = class(ESNVException);
  ESNVValueTypeMismatch = class(ESNVException);
  ESNVDuplicitValue     = class(ESNVException);

{===============================================================================
--------------------------------------------------------------------------------
                               TSimpleNamedValues
--------------------------------------------------------------------------------
===============================================================================}
type
  TSNVNamedValueType = (nvtBool,nvtInteger,nvtInt64,nvtFloat,nvtDateTime,
                        nvtCurrency,nvtText,nvtPointer);

  TSNVNamedValue = record
    Name:     String;
    Changed:  Boolean;  // internal field
    case ValueType: TSNVNamedValueType of
      nvtBool:     (BoolValue:      Boolean);
      nvtInteger:  (IntegerValue:   Integer);
      nvtInt64:    (Int64Value:     Int64);
      nvtFloat:    (FloatValue:     Extended);
      nvtDateTime: (DateTimeValue:  TDateTime);
      nvtCurrency: (CurrencyValue:  Currency);
      nvtText:     (TextValue:      PChar);
      nvtPointer:  (PointerValue:   Pointer)
  end;

{===============================================================================
    TSimpleNamedValues - class declaration
===============================================================================}
type
  TSimpleNamedValues = class(TCustomListObject)
  private
    fValues:                array of TSNVNamedValue;
    fCount:                 Integer;
    fUpdateCounter:         Integer;
    fChanged:               Boolean;
    fOnChangeEvent:         TNotifyEvent;
    fOnChangeCallback:      TNotifyCallback;
    fOnValueChangeEvent:    TIntegerEvent;
    fOnValueChangeCallback: TIntegerCallback;
    // getters/setters
    Function GetValue(Index: Integer): TSNVNamedValue;
  protected
    // value getters/setters
    Function GetBoolValue(const Name: String): Boolean; virtual;
    procedure SetBoolValue(const Name: String; Value: Boolean); virtual;
    Function GetIntegerValue(const Name: String): Integer; virtual;
    procedure SetIntegerValue(const Name: String; Value: Integer); virtual;
    Function GetInt64Value(const Name: String): Int64; virtual;
    procedure SetInt64Value(const Name: String; Value: Int64); virtual;
    Function GetFloatValue(const Name: String): Extended; virtual;
    procedure SetFloatValue(const Name: String; Value: Extended); virtual;
    Function GetDateTimeValue(const Name: String): TDateTime; virtual;
    procedure SetDateTimeValue(const Name: String; Value: TDateTime); virtual;
    Function GetCurrencyValue(const Name: String): Currency; virtual;
    procedure SetCurrencyValue(const Name: String; Value: Currency); virtual;
    Function GetTextValue(const Name: String): String; virtual;
    procedure SetTextValue(const Name: String; const Value: String); virtual;
    Function GetPointerValue(const Name: String): Pointer; virtual;
    procedure SetPointerValue(const Name: String; Value: Pointer); virtual;
    // list methods
    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;
    // change reporting
    procedure DoChange; virtual;
    procedure DoValueChange(Index: Integer); virtual;
    // utility
    Function PrepareValue(const Name: String; ValueType: TSNVNamedValueType): Integer; virtual;
    class procedure InitializeNamedValue(var NamedValue: TSNVNamedValue); virtual;
    class procedure FinalizeNamedValue(var NamedValue: TSNVNamedValue); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function IndexOf(const Name: String): Integer; overload; virtual;
    Function IndexOf(const Name: String; ValueType: TSNVNamedValueType): Integer; overload; virtual;
    Function Find(const Name: String; out Index: Integer): Boolean; overload; virtual;
    Function Find(const Name: String; ValueType: TSNVNamedValueType; out Index: Integer): Boolean; overload; virtual;
    Function Add(const Name: String; ValueType: TSNVNamedValueType): Integer; virtual;
    procedure Insert(Index: Integer; const Name: String; ValueType: TSNVNamedValueType); virtual;
    procedure Move(SrcIdx,DstIdx: Integer); virtual;
    procedure Exchange(Idx1,Idx2: Integer); virtual;
    Function Remove(const Name: String): Integer; virtual;
    procedure Delete(Index: Integer); virtual;
    procedure Clear; virtual;
    property Values[Index: Integer]: TSNVNamedValue read GetValue; default;
    // values access
    property BoolValue[const Name: String]: Boolean read GetBoolValue write SetBoolValue;
    property IntegerValue[const Name: String]: Integer read GetIntegerValue write SetIntegerValue;
    property Int64Value[const Name: String]: Int64 read GetInt64Value write SetInt64Value;
    property FloatValue[const Name: String]: Extended read GetFloatValue write SetFloatValue;
    property DateTimeValue[const Name: String]: TDateTime read GetDateTimeValue write SetDateTimeValue;
    property CurrencyValue[const Name: String]: Currency read GetCurrencyValue write SetCurrencyValue;
    property TextValue[const Name: String]: String read GetTextValue write SetTextValue;
    property PointerValue[const Name: String]: Pointer read GetPointerValue write SetPointerValue;
    // events, callbacks
    property OnChange: TNotifyEvent read fOnChangeEvent write fOnChangeEvent;
    property OnChangeEvent: TNotifyEvent read fOnChangeEvent write fOnChangeEvent;
    property OnChangeCallback: TNotifyCallback read fOnChangeCallback write fOnChangeCallback;
    property OnValueChange: TIntegerEvent read fOnValueChangeEvent write fOnValueChangeEvent;
    property OnValueChangeEvent: TIntegerEvent read fOnValueChangeEvent write fOnValueChangeEvent;
    property OnValueChangeCallback: TIntegerCallback read fOnValueChangeCallback write fOnValueChangeCallback;
  end;

implementation

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                               TSimpleNamedValues
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSimpleNamedValues - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSimpleNamedValues - private methods
-------------------------------------------------------------------------------}

Function TSimpleNamedValues.GetValue(Index: Integer): TSNVNamedValue;
begin
If CheckIndex(Index) then
  Result := fValues[Index]
else
  raise ESNVIndexOutOfBounds.CreateFmt('TSimpleNamedValues.GetValue: Index (%d) out of bounds.',[Index]);
end;

{-------------------------------------------------------------------------------
    TSimpleNamedValues - protected methods
-------------------------------------------------------------------------------}

Function TSimpleNamedValues.GetBoolValue(const Name: String): Boolean;
var
  Index:  Integer;
begin
If Find(Name,nvtBool,Index) then
  Result := fValues[Index].BoolValue
else
  raise ESNVUnknownNamedValue.CreateFmt('TSimpleNamedValues.GetBool: Unknown bool value "%s".',[Name]);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.SetBoolValue(const Name: String; Value: Boolean);
var
  Index:  Integer;
begin
Index := PrepareValue(Name,nvtBool);
fValues[Index].BoolValue := Value;
DoValueChange(Index);
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.GetIntegerValue(const Name: String): Integer;
var
  Index:  Integer;
begin
If Find(Name,nvtInteger,Index) then
  Result := fValues[Index].IntegerValue
else
  raise ESNVUnknownNamedValue.CreateFmt('TSimpleNamedValues.GetIntegerValue: Unknown integer value "%s".',[Name]);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.SetIntegerValue(const Name: String; Value: Integer);
var
  Index:  Integer;
begin
Index := PrepareValue(Name,nvtInteger);
fValues[Index].IntegerValue := Value;
DoValueChange(Index);
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.GetInt64Value(const Name: String): Int64;
var
  Index:  Integer;
begin
If Find(Name,nvtInt64,Index) then
  Result := fValues[Index].Int64Value
else
  raise ESNVUnknownNamedValue.CreateFmt('TSimpleNamedValues.GetInt64Value: Unknown int64 value "%s".',[Name]);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.SetInt64Value(const Name: String; Value: Int64);
var
  Index:  Integer;
begin
Index := PrepareValue(Name,nvtInt64);
fValues[Index].Int64Value := Value;
DoValueChange(Index);
end;
 
//------------------------------------------------------------------------------

Function TSimpleNamedValues.GetFloatValue(const Name: String): Extended;
var
  Index:  Integer;
begin
If Find(Name,nvtFloat,Index) then
  Result := fValues[Index].FloatValue
else
  raise ESNVUnknownNamedValue.CreateFmt('TSimpleNamedValues.GetFloatValue: Unknown float value "%s".',[Name]);
end;
 
//------------------------------------------------------------------------------

procedure TSimpleNamedValues.SetFloatValue(const Name: String; Value: Extended);
var
  Index:  Integer;
begin
Index := PrepareValue(Name,nvtFloat);
fValues[Index].FloatValue := Value;
DoValueChange(Index);
end;
  
//------------------------------------------------------------------------------

Function TSimpleNamedValues.GetDateTimeValue(const Name: String): TDateTime;
var
  Index:  Integer;
begin
If Find(Name,nvtDateTime,Index) then
  Result := fValues[Index].DateTimeValue
else
  raise ESNVUnknownNamedValue.CreateFmt('TSimpleNamedValues.GetDateTimeValue: Unknown datetime value "%s".',[Name]);
end;
  
//------------------------------------------------------------------------------

procedure TSimpleNamedValues.SetDateTimeValue(const Name: String; Value: TDateTime);
var
  Index:  Integer;
begin
Index := PrepareValue(Name,nvtDateTime);
fValues[Index].DateTimeValue := Value;
DoValueChange(Index);
end;
   
//------------------------------------------------------------------------------

Function TSimpleNamedValues.GetCurrencyValue(const Name: String): Currency;
var
  Index:  Integer;
begin
If Find(Name,nvtCurrency,Index) then
  Result := fValues[Index].CurrencyValue
else
  raise ESNVUnknownNamedValue.CreateFmt('TSimpleNamedValues.GetCurrencyValue: Unknown currency value "%s".',[Name]);
end;
  
//------------------------------------------------------------------------------

procedure TSimpleNamedValues.SetCurrencyValue(const Name: String; Value: Currency);
var
  Index:  Integer;
begin
Index := PrepareValue(Name,nvtCurrency);
fValues[Index].CurrencyValue := Value;
DoValueChange(Index);
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.GetTextValue(const Name: String): String;
var
  Index:  Integer;
begin
If Find(Name,nvtText,Index) then
  Result := fValues[Index].TextValue
else
  raise ESNVUnknownNamedValue.CreateFmt('TSimpleNamedValues.GetText: Unknown textual value "%s".',[Name]);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.SetTextValue(const Name: String; const Value: String);
var
  Index:  Integer;
begin
Index := PrepareValue(Name,nvtText);
with fValues[Index] do
  begin
    If Assigned(TextValue) then
      StrDispose(TextValue);
    TextValue := StrNew(PChar(Value));
  end;
DoValueChange(Index);
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.GetPointerValue(const Name: String): Pointer;
var
  Index:  Integer;
begin
If Find(Name,nvtPointer,Index) then
  Result := fValues[Index].PointerValue
else
  raise ESNVUnknownNamedValue.CreateFmt('TSimpleNamedValues.GetPointerValue: Unknown pointer value "%s".',[Name]);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.SetPointerValue(const Name: String; Value: Pointer);
var
  Index:  Integer;
begin
Index := PrepareValue(Name,nvtPointer);
fValues[Index].PointerValue := Value;
DoValueChange(Index);
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.GetCapacity: Integer;
begin
Result := Length(fValues);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.SetCapacity(Value: Integer);
var
  i:  Integer;
begin
If Value >= 0 then
  begin
    If Value <> Length(fValues) then
      begin
        If Value < fCount then
          For i := Value to HighIndex do
            FinalizeNamedValue(fValues[i]);
        SetLength(fValues,Value);
        If Value < fCount then
          begin
            fCount := Value;
            DoChange;
          end;
      end;
  end
else raise ESNVInvalidValue.CreateFmt('TSimpleNamedValues.SetCapacity: Invalid capacity value (%d).',[Value]);
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.GetCount: Integer;
begin
Result := fCount;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TSimpleNamedValues.SetCount(Value: Integer);
begin
// do nothing
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.DoChange;
begin
fChanged := True;
If fUpdateCounter <= 0 then
  begin
    If Assigned(fOnChangeEvent) then
      fOnChangeEvent(Self);
    If Assigned(fOnChangeCallback) then
      fOnChangeCallback(Self);
  end
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.DoValueChange(Index: Integer);
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    If fUpdateCounter <= 0 then
      begin
        If Assigned(fOnValueChangeEvent) then
          fOnValueChangeEvent(Self,Index);
        If Assigned(fOnValueChangeCallback) then
          fOnValueChangeCallback(Self,Index);
      end
    else fValues[Index].Changed := True;
  end
else
  begin
    // report all changed values
    If (fUpdateCounter <= 0) and (Assigned(fOnValueChangeEvent) or Assigned(fOnValueChangeCallback)) then
      For i := LowIndex to HighIndex do
        If fValues[i].Changed then
          begin
            If Assigned(fOnValueChangeEvent) then
              fOnValueChangeEvent(Self,i);
            If Assigned(fOnValueChangeCallback) then
              fOnValueChangeCallback(Self,i);
            fValues[i].Changed := False;
          end;
  end;
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.PrepareValue(const Name: String; ValueType: TSNVNamedValueType): Integer;
begin
// do create-on-write
If Find(Name,Result) then
  begin
    // value with a proper name was found, check type
    If fValues[Result].ValueType <> ValueType then
      raise ESNVValueTypeMismatch.CreateFmt('TSimpleNamedValues.PrepareValue: Wrong value type (%d) for "%s".',[Ord(ValueType),Name]);
  end
// value not found, add it
else Result := Add(Name,ValueType);
end;

//------------------------------------------------------------------------------

class procedure TSimpleNamedValues.InitializeNamedValue(var NamedValue: TSNVNamedValue);
begin
NamedValue.Name := '';
FillChar(NamedValue,SizeOf(TSNVNamedValue),0);
end;

//------------------------------------------------------------------------------

class procedure TSimpleNamedValues.FinalizeNamedValue(var NamedValue: TSNVNamedValue);
begin
NamedValue.Name := '';
If NamedValue.ValueType = nvtText then
  begin
    StrDispose(NamedValue.TextValue);
    NamedValue.TextValue := nil;
  end;
end;

{-------------------------------------------------------------------------------
    TSimpleNamedValues - public methods
-------------------------------------------------------------------------------}

constructor TSimpleNamedValues.Create;
begin
inherited Create;
SetLength(fValues,0);
fCount := 0;
fUpdateCounter := 0;
fChanged := False;
fOnChangeEvent := nil;
fOnChangeCallback := nil;
fOnValueChangeEvent := nil;
fOnValueChangeCallback := nil;
end;

//------------------------------------------------------------------------------

destructor TSimpleNamedValues.Destroy;
begin
// prevent change reporting
fOnChangeEvent := nil;
fOnChangeCallback := nil;
fOnValueChangeEvent := nil;
fOnValueChangeCallback := nil;
Clear;
inherited;
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.BeginUpdate;
begin
If fUpdateCounter <= 0 then
  fChanged := False;
Inc(fUpdateCounter);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.EndUpdate;
begin
Dec(fUpdateCounter);
If fUpdateCounter <= 0 then
  begin
    fUpdateCounter := 0;
    If fChanged then
      DoChange;
    DoValueChange(-1);  
    fChanged := False;
  end;
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.LowIndex: Integer;
begin
Result := Low(fValues);
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.HighIndex: Integer;
begin
Result := Pred(fCount);
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.IndexOf(const Name: String): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := LowIndex to HighIndex do
  If AnsiSameText(Name,fValues[i].Name) then
    begin
      Result := i;
      Break{For i};
    end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TSimpleNamedValues.IndexOf(const Name: String; ValueType: TSNVNamedValueType): Integer;
begin
Result := IndexOf(Name);
If CheckIndex(Result) then
  If fValues[Result].ValueType <> ValueType then
    Result := -1;
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.Find(const Name: String; out Index: Integer): Boolean;
begin
Index := IndexOf(Name);
Result := CheckIndex(Index);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TSimpleNamedValues.Find(const Name: String; ValueType: TSNVNamedValueType; out Index: Integer): Boolean;
begin
Index := IndexOf(Name,ValueType);
Result := CheckIndex(Index);
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.Add(const Name: String; ValueType: TSNVNamedValueType): Integer;
begin
If not Find(Name,Result) then
  begin
    Grow;
    InitializeNamedValue(fValues[fCount]);
    fValues[fCount].Name := Name;
    fValues[fCount].ValueType := ValueType;
    Result := fCount;
    Inc(fCount);
    DoChange;
  end
else raise ESNVDuplicitValue.CreateFmt('TSimpleNamedValues.Add: Value "%s" already exists.',[Name]);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.Insert(Index: Integer; const Name: String; ValueType: TSNVNamedValueType);
var
  i:  Integer;
begin
If not CheckIndex(IndexOf(Name)) then
  begin
    If CheckIndex(Index) then
      begin
        Grow;
        For i := HighIndex downto Index do
          fValues[i + 1] := fValues[i];
        InitializeNamedValue(fValues[Index]);
        fValues[Index].Name := Name;
        fValues[Index].ValueType := ValueType;
        Inc(fCount);
        DoChange;
      end
    else If Index = fCount then
      Add(Name,ValueType)
    else
      raise ESNVIndexOutOfBounds.CreateFmt('TSimpleNamedValues.Insert: Insertion index (%d) out of bounds.',[Index]);
  end
else raise ESNVDuplicitValue.CreateFmt('TSimpleNamedValues.Insert: Value "%s" already exists.',[Name]);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.Move(SrcIdx,DstIdx: Integer);
var
  Temp: TSNVNamedValue;
  i:    Integer;
begin
If SrcIdx <> DstIdx then
  begin
    If not CheckIndex(SrcIdx) then
      raise ESNVIndexOutOfBounds.CreateFmt('TSimpleNamedValues.Move: Source index (%d) out of bounds.',[SrcIdx]);
    If not CheckIndex(DstIdx) then
      raise ESNVIndexOutOfBounds.CreateFmt('TSimpleNamedValues.Move: Destination index (%d) out of bounds.',[DstIdx]);
    Temp := fValues[SrcIdx];
    If SrcIdx < DstIdx then
      For i := SrcIdx to Pred(DstIdx) do
        fValues[i] := fValues[i + 1]
    else
      For i := SrcIdx downto Succ(DstIdx) do
        fValues[i] := fValues[i - 1];
    fValues[DstIdx] := Temp;
    DoChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.Exchange(Idx1,Idx2: Integer);
var
  Temp: TSNVNamedValue;
begin
If Idx1 <> Idx2 then
  begin
    If not CheckIndex(Idx1) then
      raise ESNVIndexOutOfBounds.CreateFmt('TSimpleNamedValues.Exchange: Index 1 (%d) out of bounds.',[Idx1]);
    If not CheckIndex(Idx2) then
      raise ESNVIndexOutOfBounds.CreateFmt('TSimpleNamedValues.Exchange: Index 2 (%d) out of bounds.',[Idx2]);
    Temp := fValues[Idx1];
    fValues[Idx1] := fValues[Idx2];
    fValues[Idx2] := Temp;
    DoChange;
  end;
end;

//------------------------------------------------------------------------------

Function TSimpleNamedValues.Remove(const Name: String): Integer;
begin
Result := IndexOf(Name);
If CheckIndex(Result) then
  Delete(Result);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.Delete(Index: Integer);
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    FinalizeNamedValue(fValues[Index]);
    For i := Index to Pred(HighIndex) do
      fValues[i] := fValues[i + 1];
    fValues[HighIndex].Name := '';  // to be sure
    Dec(fCount);
    Shrink;
    DoChange;
  end
else raise ESNVIndexOutOfBounds.CreateFmt('TSimpleNamedValues.Delete: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TSimpleNamedValues.Clear;
var
  i:  Integer;
begin
For i := LowIndex to HighIndex do
  FinalizeNamedValue(fValues[i]);
SetLength(fValues,0);
fCount := 0;
DoChange;
end;

end.
