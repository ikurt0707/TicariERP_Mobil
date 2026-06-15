unit uHelpers;

interface

uses
  System.SysUtils, System.Classes, System.JSON;

type
  THelpers = class
  public
    class function FormatCurrency(AValue: Currency): string;
    class function FormatPhone(const APhone: string): string;
    class function CleanPhone(const APhone: string): string;
    class function IsValidPhone(const APhone: string): Boolean;
    class function IsValidEmail(const AEmail: string): Boolean;
    class function GetInitials(const AFullName: string): string;
    class function TruncateText(const AText: string; AMaxLen: Integer): string;
    class function DateToDisplayStr(ADate: TDateTime): string;
    class function TimeToDisplayStr(ADate: TDateTime): string;
    class function DateTimeToDisplayStr(ADate: TDateTime): string;
    class function RelativeTimeStr(ADate: TDateTime): string;
  end;

implementation

uses
  System.DateUtils, System.RegularExpressions;

{ THelpers }

class function THelpers.FormatCurrency(AValue: Currency): string;
begin
  Result := FormatFloat('#,##0.00', AValue) + ' ' + Chr($20BA);
end;

class function THelpers.FormatPhone(const APhone: string): string;
var
  LClean: string;
begin
  LClean := CleanPhone(APhone);
  if Length(LClean) = 10 then
    Result := Format('0%s %s %s %s', [
      Copy(LClean, 1, 3),
      Copy(LClean, 4, 3),
      Copy(LClean, 7, 2),
      Copy(LClean, 9, 2)])
  else if Length(LClean) = 11 then
    Result := Format('%s %s %s %s', [
      Copy(LClean, 1, 4),
      Copy(LClean, 5, 3),
      Copy(LClean, 8, 2),
      Copy(LClean, 10, 2)])
  else
    Result := APhone;
end;

class function THelpers.CleanPhone(const APhone: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(APhone) do
    if CharInSet(APhone[I], ['0'..'9']) then
      Result := Result + APhone[I];
end;

class function THelpers.IsValidPhone(const APhone: string): Boolean;
var
  LClean: string;
begin
  LClean := CleanPhone(APhone);
  Result := (Length(LClean) >= 10) and (Length(LClean) <= 11);
end;

class function THelpers.IsValidEmail(const AEmail: string): Boolean;
begin
  Result := TRegEx.IsMatch(AEmail, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
end;

class function THelpers.GetInitials(const AFullName: string): string;
var
  LParts: TArray<string>;
begin
  Result := '';
  LParts := AFullName.Trim.Split([' ']);
  if Length(LParts) > 0 then
    Result := UpperCase(Copy(LParts[0], 1, 1));
  if Length(LParts) > 1 then
    Result := Result + UpperCase(Copy(LParts[High(LParts)], 1, 1));
end;

class function THelpers.TruncateText(const AText: string; AMaxLen: Integer): string;
begin
  if Length(AText) > AMaxLen then
    Result := Copy(AText, 1, AMaxLen - 3) + '...'
  else
    Result := AText;
end;

class function THelpers.DateToDisplayStr(ADate: TDateTime): string;
begin
  if ADate > 0 then
    Result := FormatDateTime('dd.mm.yyyy', ADate)
  else
    Result := '-';
end;

class function THelpers.TimeToDisplayStr(ADate: TDateTime): string;
begin
  if ADate > 0 then
    Result := FormatDateTime('hh:nn', ADate)
  else
    Result := '-';
end;

class function THelpers.DateTimeToDisplayStr(ADate: TDateTime): string;
begin
  if ADate > 0 then
    Result := FormatDateTime('dd.mm.yyyy hh:nn', ADate)
  else
    Result := '-';
end;

class function THelpers.RelativeTimeStr(ADate: TDateTime): string;
var
  LDiff: TDateTime;
  LMinutes, LHours, LDays: Integer;
begin
  LDiff := Now - ADate;
  LMinutes := MinutesBetween(Now, ADate);
  LHours := HoursBetween(Now, ADate);
  LDays := DaysBetween(Now, ADate);

  if LMinutes < 1 then
    Result := 'Az ' + Chr($00F6) + 'nce'
  else if LMinutes < 60 then
    Result := IntToStr(LMinutes) + ' dk ' + Chr($00F6) + 'nce'
  else if LHours < 24 then
    Result := IntToStr(LHours) + ' saat ' + Chr($00F6) + 'nce'
  else if LDays < 7 then
    Result := IntToStr(LDays) + ' g' + Chr($00FC) + 'n ' + Chr($00F6) + 'nce'
  else
    Result := DateToDisplayStr(ADate);
end;

end.
