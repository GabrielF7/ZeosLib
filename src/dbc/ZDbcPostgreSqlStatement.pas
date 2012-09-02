{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{         PostgreSQL Database Connectivity Classes        }
{                                                         }
{        Originally written by Sergey Seroukhov           }
{                                                         }
{*********************************************************}

{@********************************************************}
{    Copyright (c) 1999-2006 Zeos Development Group       }
{                                                         }
{ License Agreement:                                      }
{                                                         }
{ This library is distributed in the hope that it will be }
{ useful, but WITHOUT ANY WARRANTY; without even the      }
{ implied warranty of MERCHANTABILITY or FITNESS FOR      }
{ A PARTICULAR PURPOSE.  See the GNU Lesser General       }
{ Public License for more details.                        }
{                                                         }
{ The source code of the ZEOS Libraries and packages are  }
{ distributed under the Library GNU General Public        }
{ License (see the file COPYING / COPYING.ZEOS)           }
{ with the following  modification:                       }
{ As a special exception, the copyright holders of this   }
{ library give you permission to link this library with   }
{ independent modules to produce an executable,           }
{ regardless of the license terms of these independent    }
{ modules, and to copy and distribute the resulting       }
{ executable under terms of your choice, provided that    }
{ you also meet, for each linked independent module,      }
{ the terms and conditions of the license of that module. }
{ An independent module is a module which is not derived  }
{ from or based on this library. If you modify this       }
{ library, you may extend this exception to your version  }
{ of the library, but you are not obligated to do so.     }
{ If you do not wish to do so, delete this exception      }
{ statement from your version.                            }
{                                                         }
{                                                         }
{ The project web site is located on:                     }
{   http://zeos.firmos.at  (FORUM)                        }
{   http://zeosbugs.firmos.at (BUGTRACKER)                }
{   svn://zeos.firmos.at/zeos/trunk (SVN Repository)      }
{                                                         }
{   http://www.sourceforge.net/projects/zeoslib.          }
{   http://www.zeoslib.sourceforge.net                    }
{                                                         }
{                                                         }
{                                                         }
{                                 Zeos Development Group. }
{********************************************************@}

unit ZDbcPostgreSqlStatement;

interface

{$I ZDbc.inc}

uses
  Classes, SysUtils, ZSysUtils, ZDbcIntfs, ZDbcStatement, ZDbcLogging,
  ZPlainPostgreSqlDriver, ZCompatibility, ZVariant, ZDbcGenericResolver,
  ZDbcCachedResultSet, ZDbcPostgreSql;

type

  {** Defines a PostgreSQL specific statement. }
  IZPostgreSQLStatement = interface(IZStatement)
    ['{E4FAFD96-97CC-4247-8ECC-6E0A168FAFE6}']

    function IsOidAsBlob: Boolean;
  end;

  {** Implements Generic PostgreSQL Statement. }
  TZPostgreSQLStatement = class(TZAbstractStatement, IZPostgreSQLStatement)
  private
    FPlainDriver: IZPostgreSQLPlainDriver;
    FOidAsBlob: Boolean;
  protected
    function CreateResultSet(const SQL: string;
      QueryHandle: PZPostgreSQLResult): IZResultSet;
    function GetConnectionHandle():PZPostgreSQLConnect;
  public
    constructor Create(PlainDriver: IZPostgreSQLPlainDriver;
      Connection: IZConnection; Info: TStrings);
    destructor Destroy; override;

    function ExecuteQuery(const SQL: string): IZResultSet; override;
    function ExecuteUpdate(const SQL: string): Integer; override;
    function Execute(const SQL: string): Boolean; override;

    function IsOidAsBlob: Boolean;
  end;

  {** Implements Emulated Prepared SQL Statement. }
  TZPostgreSQLEmulatedPreparedStatement = class(TZEmulatedPreparedStatement)
  private
    FPlainDriver: IZPostgreSQLPlainDriver;
  protected
    function CreateExecStatement: IZStatement; override;
    function PrepareSQLParam(ParamIndex: Integer): string; override;
    function GetConnectionHandle: PZPostgreSQLConnect;
  public
    constructor Create(PlainDriver: IZPostgreSQLPlainDriver;
      Connection: IZConnection; const SQL: string; Info: TStrings);
  end;

  {** EgonHugeist: Implements Prepared SQL Statement with AnsiString usage }
  TZPostgreSQLPreparedStatement = class(TZAbstractPreparedStatement)
  private
    FPlanName: ZAnsiString;
    FExecSQL: ZAnsiString;
    FCachedQuery: TStrings;
    FPostgreSQLConnection: IZPostgreSQLConnection;
    FPlainDriver: IZPostgreSQLPlainDriver;
    QueryHandle: PZPostgreSQLResult;

    function GetAnsiSQLQuery: ZAnsiString;

    function CreateResultSet(QueryHandle: PZPostgreSQLResult): IZResultSet;
  protected
    function PrepareAnsiSQLParam(ParamIndex: Integer; Escaped: Boolean): ZAnsiString;
    procedure PrepareInParameters; override;
    procedure BindInParameters; override;
    procedure UnPrepareInParameters; override;
  public
    constructor Create(PlainDriver: IZPostgreSQLPlainDriver;
      Connection: IZPostgreSQLConnection; const SQL: string; Info: TStrings);

    procedure Prepare; override;

    function ExecuteQuery(const SQL: ZAnsiString): IZResultSet; override;
    function ExecuteUpdate(const SQL: ZAnsiString): Integer; override;
    function Execute(const SQL: ZAnsiString): Boolean; override;

    function ExecuteQueryPrepared: IZResultSet; override;
    function ExecuteUpdatePrepared: Integer; override;
    function ExecutePrepared: Boolean; override;
  end;

  {** EgonHugeist: Implements Prepared SQL Statement based on Protocol3
    ServerVersion 7.4Up and ClientVersion 8.0Up. with CAPI usage}
  TZPostgreSQLCAPIPreparedStatement = class(TZAbstractPreparedStatement)
  private
    FPlanName: String;
    FPostgreSQLConnection: IZPostgreSQLConnection;
    FConnectionHandle: PZPostgreSQLConnect;
    FPlainDriver: IZPostgreSQLPlainDriver;
    FPrepQueryHandle: PZPostgreSQLResult;
    QueryHandle: PZPostgreSQLResult;

    FPQparamTypes: TPQparamTypes;
    FPQparamValues: TPQparamValues;
    FPQparamLengths: TPQparamLengths;
    FPQparamFormats: TPQparamFormats;
    function CreateResultSet(QueryHandle: PZPostgreSQLResult): IZResultSet;
    function ExectuteInternal(const SQL: ZAnsiString; const LogSQL: String;
      const LoggingCategory: TZLoggingCategory): PZPostgreSQLResult;
  protected
    procedure SetASQL(const Value: ZAnsiString); override;
    procedure SetWSQL(const Value: ZWideString); override;
    procedure PrepareInParameters; override;
    procedure BindInParameters; override;
    procedure UnPrepareInParameters; override;
  public
    constructor Create(PlainDriver: IZPostgreSQLPlainDriver;
      Connection: IZPostgreSQLConnection; const SQL: string; Info: TStrings);

    procedure Prepare; override;
    procedure Unprepare; override;

    function ExecuteQuery(const SQL: ZAnsiString): IZResultSet; override;
    function ExecuteUpdate(const SQL: ZAnsiString): Integer; override;
    function Execute(const SQL: ZAnsiString): Boolean; override;

    function ExecuteQueryPrepared: IZResultSet; override;
    function ExecuteUpdatePrepared: Integer; override;
    function ExecutePrepared: Boolean; override;
  end;

  {** Implements callable Postgresql Statement. }
  TZPostgreSQLCallableStatement = class(TZAbstractCallableStatement)
  private
    FPlainDriver: IZPostgreSQLPlainDriver;
    function GetProcedureSql: string;
    function FillParams(const ASql:String):String;
    function PrepareSQLParam(ParamIndex: Integer): string;
  protected
    function GetConnectionHandle:PZPostgreSQLConnect;
    function GetPlainDriver:IZPostgreSQLPlainDriver;
    function CreateResultSet(const SQL: string;
      QueryHandle: PZPostgreSQLResult): IZResultSet;
    procedure FetchOutParams(ResultSet: IZResultSet);
    procedure TrimInParameters; override;
  public
    constructor Create(Connection: IZConnection; const SQL: string; Info: TStrings);

    function ExecuteQuery(const SQL: string): IZResultSet; override;
    function ExecuteUpdate(const SQL: string): Integer; override;

    function ExecuteQueryPrepared: IZResultSet; override;
    function ExecuteUpdatePrepared: Integer; override;
    {function ExecuteUpdate(const SQL: string): Integer; override;
    function Execute(const SQL: string): Boolean; override;



    function ExecutePrepared: Boolean; override; }
  end;

  {** Implements a specialized cached resolver for PostgreSQL. }
  TZPostgreSQLCachedResolver = class(TZGenericCachedResolver, IZCachedResolver)
  protected
    function CheckKeyColumn(ColumnIndex: Integer): Boolean; override;
  end;

implementation

uses
  Types, ZMessages, ZDbcPostgreSqlResultSet, ZDbcPostgreSqlUtils, ZTokenizer,
  ZDbcUtils;

{ TZPostgreSQLStatement }

{**
  Constructs this object and assignes the main properties.
  @param PlainDriver a PostgreSQL plain driver.
  @param Connection a database connection object.
  @param Info a statement parameters.
  @param Handle a connection handle pointer.
}
constructor TZPostgreSQLStatement.Create(PlainDriver: IZPostgreSQLPlainDriver;
  Connection: IZConnection; Info: TStrings);
begin
  inherited Create(Connection, Info);
  FPlainDriver := PlainDriver;
  ResultSetType := rtScrollInsensitive;

  { Processes connection properties. }
  if Self.Info.Values['oidasblob'] <> '' then
    FOidAsBlob := StrToBoolEx(Self.Info.Values['oidasblob'])
  else
    FOidAsBlob := (Connection as IZPostgreSQLConnection).IsOidAsBlob;
end;

{**
  Destroys this object and cleanups the memory.
}
destructor TZPostgreSQLStatement.Destroy;
begin
  inherited Destroy;
end;

{**
  Checks is oid should be treated as Large Object.
  @return <code>True</code> if oid should represent a Large Object.
}
function TZPostgreSQLStatement.IsOidAsBlob: Boolean;
begin
  Result := FOidAsBlob;
end;

{**
  Creates a result set based on the current settings.
  @return a created result set object.
}
function TZPostgreSQLStatement.CreateResultSet(const SQL: string;
  QueryHandle: PZPostgreSQLResult): IZResultSet;
var
  NativeResultSet: TZPostgreSQLResultSet;
  CachedResultSet: TZCachedResultSet;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  ConnectionHandle := GetConnectionHandle();
  NativeResultSet := TZPostgreSQLResultSet.Create(FPlainDriver, Self, SQL,
  ConnectionHandle, QueryHandle, ChunkSize);

  NativeResultSet.SetConcurrency(rcReadOnly);
  if GetResultSetConcurrency = rcUpdatable then
  begin
    CachedResultSet := TZCachedResultSet.Create(NativeResultSet, SQL, nil,
      ClientCodePage);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetResolver(TZPostgreSQLCachedResolver.Create(
      Self,  NativeResultSet.GetMetadata));
    Result := CachedResultSet;
  end
  else
    Result := NativeResultSet;
end;

{**
  Executes an SQL statement that returns a single <code>ResultSet</code> object.
  @param sql typically this is a static SQL <code>SELECT</code> statement
  @return a <code>ResultSet</code> object that contains the data produced by the
    given query; never <code>null</code>
}
function TZPostgreSQLStatement.ExecuteQuery(const SQL: string): IZResultSet;
var
  QueryHandle: PZPostgreSQLResult;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  Result := nil;
  ConnectionHandle := GetConnectionHandle();
  Self.SSQL := SQL; //Preprepares the SQL and Sets the AnsiSQL
  QueryHandle := FPlainDriver.ExecuteQuery(ConnectionHandle,
    PAnsiChar(Self.ASQL));
  CheckPostgreSQLError(Connection, FPlainDriver, ConnectionHandle, lcExecute,
    SSQL, QueryHandle);
  DriverManager.LogMessage(lcExecute, FPlainDriver.GetProtocol, Self.SSQL);
  if QueryHandle <> nil then
    Result := CreateResultSet(Self.SSQL, QueryHandle)
  else
    Result := nil;
end;

{**
  Executes an SQL <code>INSERT</code>, <code>UPDATE</code> or
  <code>DELETE</code> statement. In addition,
  SQL statements that return nothing, such as SQL DDL statements,
  can be executed.

  @param sql an SQL <code>INSERT</code>, <code>UPDATE</code> or
    <code>DELETE</code> statement or an SQL statement that returns nothing
  @return either the row count for <code>INSERT</code>, <code>UPDATE</code>
    or <code>DELETE</code> statements, or 0 for SQL statements that return nothing
}
function TZPostgreSQLStatement.ExecuteUpdate(const SQL: string): Integer;
var
  QueryHandle: PZPostgreSQLResult;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  Result := -1;
  ConnectionHandle := GetConnectionHandle();
  if Connection.PreprepareSQL then
  begin
    SSQL := SQL;
    QueryHandle := FPlainDriver.ExecuteQuery(ConnectionHandle,PAnsiChar(ASQL));
  end
  else
    if Connection.GetClientCodePageInformations^.Encoding = ceUTF8 then
      QueryHandle := FPlainDriver.ExecuteQuery(ConnectionHandle,
        PAnsiChar(UTF8String(SQL)))
    else
      QueryHandle := FPlainDriver.ExecuteQuery(ConnectionHandle,
        PAnsiChar(AnsiString(SQL)));
  CheckPostgreSQLError(Connection, FPlainDriver, ConnectionHandle, lcExecute,
    SQL, QueryHandle);
  DriverManager.LogMessage(lcExecute, FPlainDriver.GetProtocol, SQL);

  if QueryHandle <> nil then
  begin
    Result := StrToIntDef(String(StrPas(FPlainDriver.GetCommandTuples(QueryHandle))), 0);
    FPlainDriver.Clear(QueryHandle);
  end;

  { Autocommit statement. }
  if Connection.GetAutoCommit then
    Connection.Commit;
end;

{**
  Executes an SQL statement that may return multiple results.
  Under some (uncommon) situations a single SQL statement may return
  multiple result sets and/or update counts.  Normally you can ignore
  this unless you are (1) executing a stored procedure that you know may
  return multiple results or (2) you are dynamically executing an
  unknown SQL string.  The  methods <code>execute</code>,
  <code>getMoreResults</code>, <code>getResultSet</code>,
  and <code>getUpdateCount</code> let you navigate through multiple results.

  The <code>execute</code> method executes an SQL statement and indicates the
  form of the first result.  You can then use the methods
  <code>getResultSet</code> or <code>getUpdateCount</code>
  to retrieve the result, and <code>getMoreResults</code> to
  move to any subsequent result(s).

  @param sql any SQL statement
  @return <code>true</code> if the next result is a <code>ResultSet</code> object;
  <code>false</code> if it is an update count or there are no more results
}
function TZPostgreSQLStatement.Execute(const SQL: string): Boolean;
var
  QueryHandle: PZPostgreSQLResult;
  ResultStatus: TZPostgreSQLExecStatusType;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  ConnectionHandle := GetConnectionHandle();
  QueryHandle := FPlainDriver.ExecuteQuery(ConnectionHandle,
    PAnsiChar(GetPrepreparedSQL(SQL)));
  CheckPostgreSQLError(Connection, FPlainDriver, ConnectionHandle, lcExecute,
    SQL, QueryHandle);
  DriverManager.LogMessage(lcExecute, FPlainDriver.GetProtocol, SQL);

  { Process queries with result sets }
  ResultStatus := FPlainDriver.GetResultStatus(QueryHandle);
  case ResultStatus of
    PGRES_TUPLES_OK:
      begin
        Result := True;
        LastResultSet := CreateResultSet(SQL, QueryHandle);
      end;
    PGRES_COMMAND_OK:
      begin
        Result := False;
        LastUpdateCount := StrToIntDef(String(StrPas(
          FPlainDriver.GetCommandTuples(QueryHandle))), 0);
        FPlainDriver.Clear(QueryHandle);
      end;
    else
      begin
        Result := False;
        LastUpdateCount := StrToIntDef(String(StrPas(
          FPlainDriver.GetCommandTuples(QueryHandle))), 0);
        FPlainDriver.Clear(QueryHandle);
      end;
  end;

  { Autocommit statement. }
  if not Result and Connection.GetAutoCommit then
    Connection.Commit;
end;

{**
  Provides connection handle from the associated IConnection
}
function TZPostgreSQLStatement.GetConnectionHandle():PZPostgreSQLConnect;
begin
  if Self.Connection = nil then
    Result := nil
  else
    Result := (self.Connection as IZPostgreSQLConnection).GetConnectionHandle;
end;

{ TZPostgreSQLEmulatedPreparedStatement }

{**
  Constructs this object and assignes the main properties.
  @param PlainDriver a PostgreSQL plain driver.
  @param Connection a database connection object.
  @param Info a statement parameters.
  @param Handle a connection handle pointer.
}
constructor TZPostgreSQLEmulatedPreparedStatement.Create(
  PlainDriver: IZPostgreSQLPlainDriver; Connection: IZConnection;
  const SQL: string; Info: TStrings);
begin
  inherited Create(Connection, SQL, Info);
  FPlainDriver := PlainDriver;
  ResultSetType := rtScrollInsensitive;
end;

{**
  Creates a temporary statement which executes queries.
  @param Info a statement parameters.
  @return a created statement object.
}
function TZPostgreSQLEmulatedPreparedStatement.CreateExecStatement: IZStatement;
begin
  Result := TZPostgreSQLStatement.Create(FPlainDriver, Connection, Info);
end;

{**
  Prepares an SQL parameter for the query.
  @param ParameterIndex the first parameter is 1, the second is 2, ...
  @return a string representation of the parameter.
}
function TZPostgreSQLEmulatedPreparedStatement.PrepareSQLParam(
  ParamIndex: Integer): string;
var
  Value: TZVariant;
  TempBlob: IZBlob;
  TempStream,TempStreamIn: TStream;
  WriteTempBlob: IZPostgreSQLBlob;
begin
  if InParamCount <= ParamIndex then
    raise EZSQLException.Create(SInvalidInputParameterCount);

  Value := InParamValues[ParamIndex];
  if DefVarManager.IsNull(Value)  then
    Result := 'NULL'
  else
  begin
    case InParamTypes[ParamIndex] of
      stBoolean:
        if SoftVarManager.GetAsBoolean(Value) then
          Result := 'TRUE'
        else
          Result := 'FALSE';
      stByte, stShort, stInteger, stLong, stBigDecimal, stFloat, stDouble:
        Result := SoftVarManager.GetAsString(Value);
      stBytes:
        Result := Self.GetConnection.GetBinaryEscapeString(AnsiString(SoftVarManager.GetAsString(Value)));
      stString:
        Result := Self.GetConnection.GetEscapeString(SoftVarManager.GetAsString(Value));
      stUnicodeString:
        {$IFDEF DELPHI12_UP}
          Result := GetConnection.GetEscapeString(SoftVarManager.GetAsUnicodeString(Value));
        {$ELSE}
        if GetConnection.GetClientCodePageInformations^.Encoding = ceUTF8 then
          Result := Self.GetConnection.GetEscapeString(PAnsiChar(UTF8Encode(SoftVarManager.GetAsUnicodeString(Value))))
        else
          Result := Self.GetConnection.GetEscapeString(PAnsiChar(AnsiString(SoftVarManager.GetAsUnicodeString(Value))));
        {$ENDIF}
      stDate:
        Result := Format('''%s''::date',
          [FormatDateTime('yyyy-mm-dd', SoftVarManager.GetAsDateTime(Value))]);
      stTime:
        Result := Format('''%s''::time',
          [FormatDateTime('hh":"mm":"ss', SoftVarManager.GetAsDateTime(Value))]);
      stTimestamp:
        Result := Format('''%s''::timestamp',
          [FormatDateTime('yyyy-mm-dd hh":"mm":"ss',
            SoftVarManager.GetAsDateTime(Value))]);
      stAsciiStream, stUnicodeStream, stBinaryStream:
        begin
          TempBlob := DefVarManager.GetAsInterface(Value) as IZBlob;
          if not TempBlob.IsEmpty then
          begin
            if (Self.GetConnection.GetClientCodePageInformations^.Encoding = ceUTF8) and
              (InParamTypes[ParamIndex] in [stAsciiStream, stUnicodeStream]) then
            begin
              TempStreamIn := TempBlob.GetStream;
              TempStream := GetValidatedUnicodeStream(TempStreamIn);
              TempStreamIn.Free;
              TempBlob.SetStream(TempStream);
              TempStream.Free;
            end;
            case InParamTypes[ParamIndex] of
              stBinaryStream:
                if ((GetConnection as IZPostgreSQLConnection).IsOidAsBlob) or
                  StrToBoolDef(Info.Values['oidasblob'], False) then
                begin
                  TempStream := TempBlob.GetStream;
                  try
                    WriteTempBlob := TZPostgreSQLBlob.Create(FPlainDriver, nil, 0,
                      Self.GetConnectionHandle, 0, ChunkSize);
                    WriteTempBlob.SetStream(TempStream);
                    WriteTempBlob.WriteBlob;
                    Result := IntToStr(WriteTempBlob.GetBlobOid);
                  finally
                    WriteTempBlob := nil;
                    TempStream.Free;
                  end;
                end
                else
                  Result := GetConnection.GetBinaryEscapeString(TempBlob.GetString);
              stAsciiStream:
                {$IFDEF DELPHI12_UP}
                if (Self.GetConnection.GetClientCodePageInformations^.Encoding = ceUTF8) then
                  Result := GetConnection.GetEscapeString(TempBlob.GetUnicodeString)
                else
                {$ENDIF}
                  Result := GetConnection.GetEscapeString(String(TempBlob.GetString));
              stUnicodeStream:
                {$IFDEF DELPHI12_UP}
                  Result := GetConnection.GetEscapeString(TempBlob.GetUnicodeString);
                {$ELSE}
                  Result := GetConnection.GetEscapeString(TempBlob.GetString);
                {$ENDIF}
            end; {case..}
          end
          else
            Result := 'NULL';
        end; {if not TempBlob.IsEmpty then}
    end;
  end;
end;

{**
  Provides connection handle from the associated IConnection
}
function TZPostgreSQLEmulatedPreparedStatement.GetConnectionHandle:PZPostgreSQLConnect;
begin
  if Self.Connection = nil then
    Result := nil
  else
    Result := (self.Connection as IZPostgreSQLConnection).GetConnectionHandle;
end;

{ TZPostgreSQLPreparedStatement }

function TZPostgreSQLPreparedStatement.GetAnsiSQLQuery;
var
  I: Integer;
  ParamIndex: Integer;
  Tokens: TStrings;

  function TokenizeSQLQuery: TStrings;
  var
    I: Integer;
    Tokens: TStrings;
    Temp: string;
  begin
    if FCachedQuery = nil then
    begin
      FCachedQuery := TStringList.Create;
      if Pos('?', SQL) > 0 then
      begin
        Tokens := Connection.GetDriver.GetTokenizer.TokenizeBufferToList(SQL, [toUnifyWhitespaces]);
        try
          Temp := '';
          for I := 0 to Tokens.Count - 1 do
          begin
            if Tokens[I] = '?' then
            begin
              FCachedQuery.Add(Temp);
              FCachedQuery.AddObject('?', Self);
              Temp := '';
            end
            else
              Temp := Temp + Tokens[I];
          end;
          if Temp <> '' then
            FCachedQuery.Add(Temp);
        finally
          Tokens.Free;
        end;
      end
      else
        FCachedQuery.Add(SQL);
    end;
    Result := FCachedQuery;
  end;
begin
  ParamIndex := 0;
  Result := '';
  Tokens := TokenizeSQLQuery;

  for I := 0 to Tokens.Count - 1 do
  begin
    if Tokens[I] = '?' then
    begin
      Result := Result + PrepareAnsiSQLParam(ParamIndex, True);
      Inc(ParamIndex);
    end
    else
      Result := Result + ZPlainString(Tokens[I]);
  end;
end;

{**
  Creates a result set based on the current settings.
  @return a created result set object.
}
function TZPostgreSQLPreparedStatement.CreateResultSet(QueryHandle:
  PZPostgreSQLResult): IZResultSet;
var
  NativeResultSet: TZPostgreSQLResultSet;
  CachedResultSet: TZCachedResultSet;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  ConnectionHandle := FPostgreSQLConnection.GetConnectionHandle;
  NativeResultSet := TZPostgreSQLResultSet.Create(FPlainDriver, Self, Self.SQL,
  ConnectionHandle, QueryHandle, ChunkSize);

  NativeResultSet.SetConcurrency(rcReadOnly);
  if GetResultSetConcurrency = rcUpdatable then
  begin
    CachedResultSet := TZCachedResultSet.Create(NativeResultSet, Self.SQL, nil,
      ClientCodePage);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetResolver(TZPostgreSQLCachedResolver.Create(
      Self,  NativeResultSet.GetMetadata));
    Result := CachedResultSet;
  end
  else
    Result := NativeResultSet;
end;

function TZPostgreSQLPreparedStatement.PrepareAnsiSQLParam(ParamIndex: Integer;
  Escaped: Boolean): ZAnsiString;
var
  Value: TZVariant;
  TempBlob: IZBlob;
  TempStream: TStream;
  WriteTempBlob: IZPostgreSQLBlob;
  TempStreamIn: TStream;
begin
  if InParamCount <= ParamIndex then
    raise EZSQLException.Create(SInvalidInputParameterCount);

  Value := InParamValues[ParamIndex];
  if DefVarManager.IsNull(Value)  then
    Result := 'NULL'
  else
  begin
    case InParamTypes[ParamIndex] of
      stBoolean:
        if SoftVarManager.GetAsBoolean(Value) then
          Result := 'TRUE'
        else
          Result := 'FALSE';
      stByte, stShort, stInteger, stLong, stBigDecimal, stFloat, stDouble:
        Result := #39+ZAnsiString(SoftVarManager.GetAsString(Value))+#39;
      stBytes:
        Result := FPostgreSQLConnection.EncodeBinary(AnsiString(SoftVarManager.GetAsString(Value)));
      stString:
        Result :=  Self.FPlainDriver.EscapeString(FPostgreSQLConnection.GetConnectionHandle,
          ZPlainString(SoftVarManager.GetAsString(Value)), FPostgreSQLConnection.GetEncoding);
      stUnicodeString:
        begin
          if GetConnection.GetClientCodePageInformations^.Encoding = ceUTF8 then
            Result := UTF8Encode(SoftVarManager.GetAsUnicodeString(Value))
          else
            Result := AnsiString(SoftVarManager.GetAsUnicodeString(Value));
          Result := Self.FPlainDriver.EscapeString(FPostgreSQLConnection.GetConnectionHandle,
            Result, FPostgreSQLConnection.GetEncoding)
        end;
      stDate:
        if Escaped then
          Result := ZAnsiString(Format('''%s''::date',
            [FormatDateTime('yyyy-mm-dd', SoftVarManager.GetAsDateTime(Value))]))
        else
          Result := #39+ZAnsiString(FormatDateTime('yyyy-mm-dd', SoftVarManager.GetAsDateTime(Value)))+#39;
      stTime:
        if Escaped then
          Result := ZAnsiString(Format('''%s''::time',
            [FormatDateTime('hh":"mm":"ss', SoftVarManager.GetAsDateTime(Value))]))
        else
          Result := #39+ZAnsiString(FormatDateTime('hh":"mm":"ss', SoftVarManager.GetAsDateTime(Value)))+#39;
      stTimestamp:
        if Escaped then
          Result := ZAnsiString(Format('''%s''::timestamp',
           [FormatDateTime('yyyy-mm-dd hh":"mm":"ss', SoftVarManager.GetAsDateTime(Value))]))
        else
          Result := #39+ZAnsiString(FormatDateTime('yyyy-mm-dd hh":"mm":"ss', SoftVarManager.GetAsDateTime(Value)))+#39;
      stAsciiStream, stUnicodeStream, stBinaryStream:
        begin
          TempBlob := DefVarManager.GetAsInterface(Value) as IZBlob;
          if not TempBlob.IsEmpty then
          begin
            if (Self.GetConnection.GetClientCodePageInformations^.Encoding = ceUTF8) and
              (InParamTypes[ParamIndex] in [stAsciiStream, stUnicodeStream]) then
            begin
              TempStreamIn := TempBlob.GetStream;
              TempStream := GetValidatedUnicodeStream(TempStreamIn);
              TempStreamIn.Free;
              TempBlob.SetStream(TempStream);
              TempStream.Free;
            end;
            case InParamTypes[ParamIndex] of
              stBinaryStream:
                if ((GetConnection as IZPostgreSQLConnection).IsOidAsBlob) or
                  StrToBoolDef(Info.Values['oidasblob'], False) then
                begin
                  TempStream := TempBlob.GetStream;
                  try
                    WriteTempBlob := TZPostgreSQLBlob.Create(FPlainDriver, nil, 0,
                      FPostgreSQLConnection.GetConnectionHandle, 0, ChunkSize);
                    WriteTempBlob.SetStream(TempStream);
                    WriteTempBlob.WriteBlob;
                    Result := ZAnsiString(IntToStr(WriteTempBlob.GetBlobOid));
                  finally
                    WriteTempBlob := nil;
                    TempStream.Free;
                  end;
                end
                else
                  Result := FPostgreSQLConnection.EncodeBinary(TempBlob.GetString);
              stAsciiStream, stUnicodeStream:
                Result := FPlainDriver.EscapeString(FPostgreSQLConnection.GetConnectionHandle,
                  TempBlob.GetString, FPostgreSQLConnection.GetEncoding)
            end; {case..}
            TempBlob := nil;
          end
          else
            Result := 'NULL';
        end; {if not TempBlob.IsEmpty then}
    end;
  end;
end;

procedure TZPostgreSQLPreparedStatement.PrepareInParameters;
var
  I, N: Integer;
  Tokens: TStrings;
  TempSQL: String;
  QueryHandle: PZPostgreSQLResult;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  if Pos('?', SQL) > 0 then
  begin
    Tokens := Connection.GetDriver.GetTokenizer.
      TokenizeBufferToList(SQL, [toUnifyWhitespaces]);
    try
      TempSQL := 'PREPARE '+ZDbcString(FPlanName)+' AS ';

      {EgonHugeist: This i've commented out. For those who are able/take care to
        declare the right Parameter-Types it speeds the Statements up too,
        because PostgreSQL must not finc the right types. On the other hand if
        you assign a type like Params[0].AsString := IntToStr(ID); it makes
        trouble, because PosgreSQL does not convert or check the types again!
        Without pre-defining the types PostgreSQL does the casts.
      TempSQL := 'PREPARE '+ZDbcString(FPlanName)+'(';
      for i := 0 to InParamCount -1 do
        if I = 0 then
          TempSQL := TempSQL + SQLTypeToPostgreSQL(Self.InParamTypes[i], FPostgreSQLConnection.IsOidAsBlob)
        else
          TempSQL := TempSQL + ', '+ SQLTypeToPostgreSQL(Self.InParamTypes[i], FPostgreSQLConnection.IsOidAsBlob);
      TempSQL := TempSQL + ') AS ';}
      N := 0;
      for I := 0 to Tokens.Count - 1 do
      begin
        if Tokens[I] = '?' then
        begin
          Inc(N);
          TempSQL := TempSQL + '$' + IntToStr(N);
        end else
          TempSQL := TempSQL + Tokens[I];
      end;
    finally
      Tokens.Free;
    end;
  end
  else Exit;

  {$IFDEF DELPHI12_UP}WSQL{$ELSE}ASQL{$ENDIF} := TempSQL;
  ConnectionHandle := FPostgreSQLConnection.GetConnectionHandle;
  QueryHandle := FPlainDriver.ExecuteQuery(ConnectionHandle,
    PAnsiChar(ASQL));
  CheckPostgreSQLError(Connection, FPlainDriver, ConnectionHandle, lcPrepStmt,
    SSQL, QueryHandle);
  DriverManager.LogMessage(lcPrepStmt, FPlainDriver.GetProtocol, SSQL);
  FPlainDriver.Clear(QueryHandle);
end;

procedure TZPostgreSQLPreparedStatement.BindInParameters;
var
  I: Integer;
begin
  if Self.InParamCount > 0 then
  begin
    if Prepared then
    begin
      FExecSQL := 'EXECUTE '+FPlanName+'(';
      for i := 0 to InParamCount -1 do
        if I = 0 then
          FExecSQL := FExecSQL+PrepareAnsiSQLParam(i, False)
        else
          FExecSQL := FExecSQL+','+PrepareAnsiSQLParam(i, False);
      FExecSQL := FExecSQL+');';
    end
    else
      FExecSQL := GetAnsiSQLQuery;
  end
  else
    FExecSQL := ASQL;
end;

procedure TZPostgreSQLPreparedStatement.UnPrepareInParameters;
begin
  if Prepared then
  begin
    ASQL := 'DEALLOCATE '+FPlanName+';';
    Execute(ASQL);
  end;
end;

constructor TZPostgreSQLPreparedStatement.Create(PlainDriver: IZPostgreSQLPlainDriver;
  Connection: IZPostgreSQLConnection; const SQL: string; Info: TStrings);
begin
  inherited Create(Connection, SQL, Info);
  FPostgreSQLConnection := Connection;
  FPlainDriver := PlainDriver;
  ResultSetType := rtScrollInsensitive;
  FPlanName := '"'+AnsiString(IntToStr(Hash(ASQL)+Cardinal(FStatementId)+NativeUInt(Connection.GetConnectionHandle)))+'"';
end;

procedure TZPostgreSQLPreparedStatement.Prepare;
begin
  { EgonHugeist: assume automated Prepare after third execution. That's the way
    the JDBC Drivers go too... }
  if (not Prepared ) and ( InParamCount > 0 ) and ( ExecCount > 2 ) then
    inherited Prepare;
  BindInParameters;
end;

{**
  Executes an SQL statement that returns a single <code>ResultSet</code> object.
  @param sql typically this is a static SQL <code>SELECT</code> statement
  @return a <code>ResultSet</code> object that contains the data produced by the
    given query; never <code>null</code>
}
function TZPostgreSQLPreparedStatement.ExecuteQuery(const SQL: ZAnsiString): IZResultSet;
begin
  Result := nil;
  ASQL := SQL; //Preprepares the SQL and Sets the AnsiSQL
  QueryHandle := FPlainDriver.ExecuteQuery(FPostgreSQLConnection.GetConnectionHandle,
    PAnsiChar(ASQL));
  CheckPostgreSQLError(Connection, FPlainDriver,
    FPostgreSQLConnection.GetConnectionHandle, lcExecute, SSQL, QueryHandle);
  DriverManager.LogMessage(lcExecute, FPlainDriver.GetProtocol, Self.SSQL);
  if QueryHandle <> nil then
    Result := CreateResultSet(QueryHandle)
  else
    Result := nil;
end;

{**
  Executes an SQL <code>INSERT</code>, <code>UPDATE</code> or
  <code>DELETE</code> statement. In addition,
  SQL statements that return nothing, such as SQL DDL statements,
  can be executed.

  @param sql an SQL <code>INSERT</code>, <code>UPDATE</code> or
    <code>DELETE</code> statement or an SQL statement that returns nothing
  @return either the row count for <code>INSERT</code>, <code>UPDATE</code>
    or <code>DELETE</code> statements, or 0 for SQL statements that return nothing
}
function TZPostgreSQLPreparedStatement.ExecuteUpdate(const SQL: ZAnsiString): Integer;
var
  QueryHandle: PZPostgreSQLResult;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  Result := -1;
  ASQL := SQL; //Preprepares the SQL and Sets the AnsiSQL
  ConnectionHandle := Self.FPostgreSQLConnection.GetConnectionHandle;
  QueryHandle := FPlainDriver.ExecuteQuery(ConnectionHandle, PAnsiChar(ASQL));
  CheckPostgreSQLError(Connection, FPlainDriver, ConnectionHandle, lcExecute,
    SSQL, QueryHandle);
  DriverManager.LogMessage(lcExecute, FPlainDriver.GetProtocol, SSQL);

  if QueryHandle <> nil then
  begin
    Result := StrToIntDef(String(StrPas(FPlainDriver.GetCommandTuples(QueryHandle))), 0);
    FPlainDriver.Clear(QueryHandle);
  end;

  { Autocommit statement. }
  if Connection.GetAutoCommit then
    Connection.Commit;
end;

{**
  Executes an SQL statement that may return multiple results.
  Under some (uncommon) situations a single SQL statement may return
  multiple result sets and/or update counts.  Normally you can ignore
  this unless you are (1) executing a stored procedure that you know may
  return multiple results or (2) you are dynamically executing an
  unknown SQL string.  The  methods <code>execute</code>,
  <code>getMoreResults</code>, <code>getResultSet</code>,
  and <code>getUpdateCount</code> let you navigate through multiple results.

  The <code>execute</code> method executes an SQL statement and indicates the
  form of the first result.  You can then use the methods
  <code>getResultSet</code> or <code>getUpdateCount</code>
  to retrieve the result, and <code>getMoreResults</code> to
  move to any subsequent result(s).

  @param sql any SQL statement
  @return <code>true</code> if the next result is a <code>ResultSet</code> object;
  <code>false</code> if it is an update count or there are no more results
}
function TZPostgreSQLPreparedStatement.Execute(const SQL: ZAnsiString): Boolean;
var
  QueryHandle: PZPostgreSQLResult;
  ResultStatus: TZPostgreSQLExecStatusType;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  ASQL := SQL; //Preprepares the SQL and Sets the AnsiSQL
  ConnectionHandle := FPostgreSQLConnection.GetConnectionHandle;
  QueryHandle := FPlainDriver.ExecuteQuery(ConnectionHandle,
    PAnsiChar(ASQL));
  CheckPostgreSQLError(Connection, FPlainDriver, ConnectionHandle, lcExecute,
    SSQL, QueryHandle);
  DriverManager.LogMessage(lcExecute, FPlainDriver.GetProtocol, SSQL);

  { Process queries with result sets }
  ResultStatus := FPlainDriver.GetResultStatus(QueryHandle);
  case ResultStatus of
    PGRES_TUPLES_OK:
      begin
        Result := True;
        LastResultSet := CreateResultSet(QueryHandle);
      end;
    PGRES_COMMAND_OK:
      begin
        Result := False;
        LastUpdateCount := StrToIntDef(String(StrPas(
          FPlainDriver.GetCommandTuples(QueryHandle))), 0);
        FPlainDriver.Clear(QueryHandle);
      end;
    else
      begin
        Result := False;
        LastUpdateCount := StrToIntDef(String(StrPas(
          FPlainDriver.GetCommandTuples(QueryHandle))), 0);
        FPlainDriver.Clear(QueryHandle);
      end;
  end;

  { Autocommit statement. }
  if not Result and Connection.GetAutoCommit then
    Connection.Commit;
end;

{**
  Executes the SQL query in this <code>PreparedStatement</code> object
  and returns the result set generated by the query.

  @return a <code>ResultSet</code> object that contains the data produced by the
    query; never <code>null</code>
}
function TZPostgreSQLPreparedStatement.ExecuteQueryPrepared: IZResultSet;
begin
  Prepare;
  Result := ExecuteQuery(FExecSQL);
  inherited ExecuteQueryPrepared;
end;

{**
  Executes the SQL INSERT, UPDATE or DELETE statement
  in this <code>PreparedStatement</code> object.
  In addition,
  SQL statements that return nothing, such as SQL DDL statements,
  can be executed.

  @return either the row count for INSERT, UPDATE or DELETE statements;
  or 0 for SQL statements that return nothing
}
function TZPostgreSQLPreparedStatement.ExecuteUpdatePrepared: Integer;
begin
  Prepare;
  Result := ExecuteUpdate(FExecSQL);
  inherited ExecuteUpdatePrepared;
end;

{**
  Executes any kind of SQL statement.
  Some prepared statements return multiple results; the <code>execute</code>
  method handles these complex statements as well as the simpler
  form of statements handled by the methods <code>executeQuery</code>
  and <code>executeUpdate</code>.
  @see Statement#execute
}
function TZPostgreSQLPreparedStatement.ExecutePrepared: Boolean;
begin
  Prepare;
  Result := Execute(FExecSQL);
  inherited ExecutePrepared;
end;

{ TZPostgreSQLCAPIPreparedStatement }

function TZPostgreSQLCAPIPreparedStatement.CreateResultSet(QueryHandle: PZPostgreSQLResult): IZResultSet;
var
  NativeResultSet: TZPostgreSQLResultSet;
  CachedResultSet: TZCachedResultSet;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  ConnectionHandle := FPostgreSQLConnection.GetConnectionHandle;
  NativeResultSet := TZPostgreSQLResultSet.Create(FPlainDriver, Self, Self.SQL,
  ConnectionHandle, QueryHandle, ChunkSize);

  NativeResultSet.SetConcurrency(rcReadOnly);
  if GetResultSetConcurrency = rcUpdatable then
  begin
    CachedResultSet := TZCachedResultSet.Create(NativeResultSet, Self.SQL, nil,
      ClientCodePage);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetResolver(TZPostgreSQLCachedResolver.Create(
      Self,  NativeResultSet.GetMetadata));
    Result := CachedResultSet;
  end
  else
    Result := NativeResultSet;
end;

function TZPostgreSQLCAPIPreparedStatement.ExectuteInternal(const SQL: ZAnsiString;
  const LogSQL: String; const LoggingCategory: TZLoggingCategory): PZPostgreSQLResult;
begin
  case LoggingCategory of
    lcPrepStmt:
      Result := FPlainDriver.Prepare(FConnectionHandle, PAnsiChar(ZAnsiString(FPlanName)),
        PAnsiChar(SQL), InParamCount, nil);
    lcExecPrepStmt:
      Result := FPlainDriver.ExecPrepared(FConnectionHandle,
        PAnsiChar(ZAnsiString(FPLanName)), InParamCount, @FPQparamValues, nil{@FPQparamLengths}, nil, 0);
    else
      Result := FPlainDriver.ExecuteQuery(FConnectionHandle, PAnsiChar(SQL));
  end;
  CheckPostgreSQLError(Connection, FPlainDriver, FConnectionHandle,
    LoggingCategory, LogSQL, Result);
  DriverManager.LogMessage(LoggingCategory, FPlainDriver.GetProtocol, LogSQL);
end;

procedure TZPostgreSQLCAPIPreparedStatement.SetASQL(const Value: ZAnsiString);
begin
  if ( ASQL <> Value ) and Prepared then
    Unprepare;
  inherited SetASQL(Value);
end;

procedure TZPostgreSQLCAPIPreparedStatement.SetWSQL(const Value: ZWideString);
begin
  if ( WSQL <> Value ) and Prepared then
    Unprepare;
  inherited SetWSQL(Value);
end;

procedure TZPostgreSQLCAPIPreparedStatement.PrepareInParameters;
begin
  SetLength(FPQparamTypes, InParamCount);
  SetLength(FPQparamValues, InParamCount);
  SetLength(FPQparamLengths, InParamCount);
  SetLength(FPQparamFormats, InParamCount);
end;

procedure TZPostgreSQLCAPIPreparedStatement.BindInParameters;
var
  Value: TZVariant;
  TempBlob: IZBlob;
  TempStream, TempStreamIn: TStream;
  WriteTempBlob: IZPostgreSQLBlob;
  ParamIndex: Integer;

  procedure UpdateString(Value: ZAnsiString; const Index: Integer;
    const ALen: Integer = -1);
  var
    len: Integer;
  begin
    Value := #39+Value+#39;
    if ALen = -1 then
    begin
      FPQparamValues[ParamIndex] := StrNew(PAnsichar(Value));
      FPQparamLengths[ParamIndex] := StrLen(FPQparamValues[ParamIndex]);
    end
    else
    begin
      Len := ALen+2; //Add quotes
      ReallocMem(FPQparamValues[ParamIndex], Len);
      System.Move(PAnsichar(Value)^, FPQparamValues[ParamIndex], Len);
      FPQparamLengths[ParamIndex] := Len;
    end;
  end;

  procedure UpdateNull(Index: Integer);
  begin
    FreeMem(FPQparamValues[ParamIndex]);
    FPQparamValues[ParamIndex] := nil;
    FPQparamLengths[ParamIndex] := 0;
  end;
begin
  if InParamCount <> High(FPQparamValues)+1 then
    raise EZSQLException.Create(SInvalidInputParameterCount);

  for ParamIndex := 0 to InParamCount -1 do
  begin
    Value := InParamValues[ParamIndex];
    if DefVarManager.IsNull(Value)  then
      UpdateNull(ParamIndex)
    else
    begin
      case InParamTypes[ParamIndex] of
        stBoolean:
          UpdateString(ZAnsiString(UpperCase(BoolToStrEx(SoftVarManager.GetAsBoolean(Value)))), ParamIndex);
        stByte, stShort, stInteger, stLong, stBigDecimal, stFloat, stDouble:
          UpdateString(ZAnsiString(SoftVarManager.GetAsString(Value)), ParamIndex);
        stBytes:
          UpdateString(ZAnsiString(SoftVarManager.GetAsString(Value)), ParamIndex, Length(SoftVarManager.GetAsString(Value)));
        stString:
          UpdateString(ZPlainString(SoftVarManager.GetAsString(Value), GetConnection.GetEncoding), ParamIndex);
        stUnicodeString:
          if GetConnection.GetEncoding = ceUTF8 then
            UpdateString(UTF8Encode(SoftVarManager.GetAsUnicodeString(Value)), ParamIndex)
          else
            UpdateString(AnsiString(SoftVarManager.GetAsUnicodeString(Value)), ParamIndex);
        stDate:
          UpdateString(ZAnsiString(FormatDateTime('yyyy-mm-dd', SoftVarManager.GetAsDateTime(Value))), ParamIndex);
        stTime:
          UpdateString(ZAnsiString(FormatDateTime('hh":"mm":"ss', SoftVarManager.GetAsDateTime(Value))), ParamIndex);
        stTimestamp:
          UpdateString(ZAnsiString(FormatDateTime('yyyy-mm-dd hh":"mm":"ss', SoftVarManager.GetAsDateTime(Value))), ParamIndex);
        stAsciiStream, stUnicodeStream, stBinaryStream:
          begin
            TempBlob := DefVarManager.GetAsInterface(Value) as IZBlob;
            if not TempBlob.IsEmpty then
            begin
              if (GetConnection.GetEncoding = ceUTF8) and
                (InParamTypes[ParamIndex] in [stAsciiStream, stUnicodeStream]) then
              begin
                TempStreamIn := TempBlob.GetStream;
                TempStream := GetValidatedUnicodeStream(TempStreamIn);
                TempStreamIn.Free;
                TempBlob.SetStream(TempStream);
                TempStream.Free;
              end;
              case InParamTypes[ParamIndex] of
                stBinaryStream:
                  if ((GetConnection as IZPostgreSQLConnection).IsOidAsBlob) or
                    StrToBoolDef(Info.Values['oidasblob'], False) then
                  begin
                    TempStream := TempBlob.GetStream;
                    try
                      WriteTempBlob := TZPostgreSQLBlob.Create(FPlainDriver, nil, 0,
                        FPostgreSQLConnection.GetConnectionHandle, 0, ChunkSize);
                      WriteTempBlob.SetStream(TempStream);
                      WriteTempBlob.WriteBlob;
                      UpdateString(ZAnsiString(IntToStr(WriteTempBlob.GetBlobOid)), ParamIndex);
                    finally
                      WriteTempBlob := nil;
                      TempStream.Free;
                    end;
                  end
                  else
                    UpdateString(TempBlob.GetString, ParamIndex);
                stAsciiStream, stUnicodeStream:
                  UpdateString(TempBlob.GetString, ParamIndex);
              end; {case..}
              TempBlob := nil;
            end
            else
              UpdateNull(ParamIndex);
          end; {if not TempBlob.IsEmpty then}
      end;
    end;
  end;
end;

procedure TZPostgreSQLCAPIPreparedStatement.UnPrepareInParameters;
var
  I: Integer;
begin
  { release allocated memory }
  for i := 0 to high(FPQparamTypes) do
  begin
    FreeMem(FPQparamTypes[i]);
    StrDispose(FPQparamValues[i]);

  end;
  SetLength(FPQparamTypes, 0);
  SetLength(FPQparamValues, 0);
  SetLength(FPQparamLengths, 0);
  SetLength(FPQparamFormats, 0);
end;

constructor TZPostgreSQLCAPIPreparedStatement.Create(PlainDriver: IZPostgreSQLPlainDriver;
  Connection: IZPostgreSQLConnection; const SQL: string; Info: TStrings);
begin
  inherited Create(Connection, SQL, Info);
  FPostgreSQLConnection := Connection;
  FPlainDriver := PlainDriver;
  ResultSetType := rtScrollInsensitive;
  FConnectionHandle := Connection.GetConnectionHandle;
  FPlanName := '"'+IntToStr(Hash(ASQL)+Cardinal(FStatementId)+NativeUInt(FConnectionHandle))+'"';
end;

procedure TZPostgreSQLCAPIPreparedStatement.Prepare;
var
  Tokens: TStrings;
  TempSQL: String;
  N, I: Integer;
begin
  if not Prepared then
  begin
    N := 0;
    if Pos('?', SQL) > 0 then
    begin
      Tokens := Connection.GetDriver.GetTokenizer.
        TokenizeBufferToList(SQL, [toUnifyWhitespaces]);
      try
        for I := 0 to Tokens.Count - 1 do
        begin
          if Tokens[I] = '?' then
          begin
            Inc(N);
            TempSQL := TempSQL + '$' + IntToStr(N);
          end else
            TempSQL := TempSQL + Tokens[I];
        end;
      finally
        Tokens.Free;
      end;
    end
    else TempSQL := SQL;

    if ( N > 0 ) or ( ExecCount > 2 ) then //prepare only if Params are available
    begin
      FPrepQueryHandle := ExectuteInternal(GetPrepreparedSQL(TempSQL), 'PREPRARE '#39+TempSQL+#39, lcPrepStmt);
      inherited Prepare;
      //FPlainDriver.Clear(QueryHandle);
    end
    //else
      //QueryHandle := ExectuteInternal(ASQL, SSQL, lcExecute);


  end;
end;

procedure TZPostgreSQLCAPIPreparedStatement.Unprepare;
var
  TempSQL: String;
begin
  if Prepared then
  begin
    inherited Unprepare;
    TempSQL := 'DEALLOCATE '+FPlanName+';';
    QueryHandle := ExectuteInternal(ZAnsiString(TempSQL), TempSQL, lcExecute);
    FPlainDriver.Clear(QueryHandle);
    FPlainDriver.Clear(FPrepQueryHandle);
  end;
end;

function TZPostgreSQLCAPIPreparedStatement.ExecuteQuery(const SQL: ZAnsiString): IZResultSet;
begin
  {$IFNDEF DELPHI12_UP}ASQL := SQL;{$ENDIF} //Preprepares the SQL and Sets the AnsiSQL
  Result := ExecuteQueryPrepared;
end;

function TZPostgreSQLCAPIPreparedStatement.ExecuteUpdate(const SQL: ZAnsiString): Integer;
begin
  {$IFNDEF DELPHI12_UP}ASQL := SQL;{$ENDIF} //Preprepares the SQL and Sets the AnsiSQL
  Result := ExecuteUpdatePrepared;
end;

function TZPostgreSQLCAPIPreparedStatement.Execute(const SQL: ZAnsiString): Boolean;
begin
  {$IFNDEF DELPHI12_UP}ASQL := SQL;{$ENDIF} //Preprepares the SQL and Sets the AnsiSQL
  Result := ExecutePrepared;
end;


function TZPostgreSQLCAPIPreparedStatement.ExecuteQueryPrepared: IZResultSet;
begin
  Result := nil;

  Prepare;
  if Prepared  then
  begin
    BindInParameters;
    QueryHandle := Self.ExectuteInternal(ASQL, SSQL, lcExecPrepStmt);
  end
  else
    QueryHandle := Self.ExectuteInternal(ASQL, SSQL, lcExecute);
  if QueryHandle <> nil then
    Result := CreateResultSet(QueryHandle)
  else
    Result := nil;
  inherited ExecuteQueryPrepared;
end;

function TZPostgreSQLCAPIPreparedStatement.ExecuteUpdatePrepared: Integer;
begin
  Result := -1;
  Prepare;

  if Prepared  then
  begin
    BindInParameters;
    QueryHandle := Self.ExectuteInternal(ASQL, SSQL, lcExecPrepStmt);
  end
  else
    QueryHandle := Self.ExectuteInternal(ASQL, SSQL, lcExecute);

  if QueryHandle <> nil then
  begin
    Result := StrToIntDef(String(StrPas(FPlainDriver.GetCommandTuples(QueryHandle))), 0);
    FPlainDriver.Clear(QueryHandle);
  end;

  { Autocommit statement. }
  if Connection.GetAutoCommit then
    Connection.Commit;

  inherited ExecuteUpdatePrepared;
end;

function TZPostgreSQLCAPIPreparedStatement.ExecutePrepared: Boolean;
var
  ResultStatus: TZPostgreSQLExecStatusType;
begin
  Prepare;
  if Prepared  then
  begin
    BindInParameters;
    QueryHandle := Self.ExectuteInternal(ASQL, SSQL, lcExecPrepStmt);
  end
  else
    QueryHandle := Self.ExectuteInternal(ASQL, SSQL, lcExecute);

  { Process queries with result sets }
  ResultStatus := FPlainDriver.GetResultStatus(QueryHandle);
  case ResultStatus of
    PGRES_TUPLES_OK:
      begin
        Result := True;
        LastResultSet := CreateResultSet(QueryHandle);
      end;
    PGRES_COMMAND_OK:
      begin
        Result := False;
        LastUpdateCount := StrToIntDef(String(StrPas(
          FPlainDriver.GetCommandTuples(QueryHandle))), 0);
        FPlainDriver.Clear(QueryHandle);
      end;
    else
      begin
        Result := False;
        LastUpdateCount := StrToIntDef(String(StrPas(
          FPlainDriver.GetCommandTuples(QueryHandle))), 0);
        FPlainDriver.Clear(QueryHandle);
      end;
  end;

  { Autocommit statement. }
  if not Result and Connection.GetAutoCommit then
    Connection.Commit;

  inherited ExecutePrepared;
end;


{ TZPostgreSQLCallableStatement }

{**
  Constructs this object and assignes the main properties.
  @param Connection a database connection object.
  @param Info a statement parameters.
  @param Handle a connection handle pointer.
}
constructor TZPostgreSQLCallableStatement.Create(
  Connection: IZConnection; const SQL: string; Info: TStrings);
begin
  inherited Create(Connection, SQL, Info);
  ResultSetType := rtScrollInsensitive;
  FPlainDriver := (Connection as IZPostgreSQLConnection).GetPlainDriver;
end;

{**
  Provides connection handle from the associated IConnection
  @return a PostgreSQL connection handle.
}
function TZPostgreSQLCallableStatement.GetConnectionHandle:PZPostgreSQLConnect;
begin
  if Self.Connection = nil then
    Result := nil
  else
    Result := (self.Connection as IZPostgreSQLConnection).GetConnectionHandle;
end;

{**
  Creates a result set based on the current settings.
  @return a created result set object.
}
function TZPostgreSQLCallableStatement.CreateResultSet(const SQL: string;
      QueryHandle: PZPostgreSQLResult): IZResultSet;
var
  NativeResultSet: TZPostgreSQLResultSet;
  CachedResultSet: TZCachedResultSet;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  ConnectionHandle := GetConnectionHandle();
  NativeResultSet := TZPostgreSQLResultSet.Create(GetPlainDriver, Self, SQL,
    ConnectionHandle, QueryHandle, ChunkSize);
  NativeResultSet.SetConcurrency(rcReadOnly);
  if GetResultSetConcurrency = rcUpdatable then
  begin
    CachedResultSet := TZCachedResultSet.Create(NativeResultSet, SQL, nil,
      ClientCodePage);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetResolver(TZPostgreSQLCachedResolver.Create(
      Self,  NativeResultSet.GetMetadata));
    Result := CachedResultSet;
  end
  else
    Result := NativeResultSet;
end;

{**
   Returns plain draiver from connection object
   @return a PlainDriver object
}
function TZPostgreSQLCallableStatement.GetPlainDriver():IZPostgreSQLPlainDriver;
begin
  if self.Connection <> nil then
    Result := (self.Connection as IZPostgreSQLConnection).GetPlainDriver
  else
    Result := nil;
end;

{**
  Prepares an SQL parameter for the query.
  @param ParameterIndex the first parameter is 1, the second is 2, ...
  @return a string representation of the parameter.
}
function TZPostgreSQLCallableStatement.PrepareSQLParam(
  ParamIndex: Integer): string;
var
  Value: TZVariant;
  TempBlob: IZBlob;
  TempStream: TStream;
  WriteTempBlob: IZPostgreSQLBlob;
  TempStreamIn: TStream;
begin
  if InParamCount <= ParamIndex then
    raise EZSQLException.Create(SInvalidInputParameterCount);

  Value := InParamValues[ParamIndex];
  if DefVarManager.IsNull(Value)  then
    Result := 'NULL'
  else
  begin
    case InParamTypes[ParamIndex] of
      stBoolean:
        if SoftVarManager.GetAsBoolean(Value) then
          Result := 'TRUE'
        else
          Result := 'FALSE';
      stByte, stShort, stInteger, stLong, stBigDecimal, stFloat, stDouble:
        Result := SoftVarManager.GetAsString(Value);
      stBytes:
        Result := Self.GetConnection.GetBinaryEscapeString(AnsiString(SoftVarManager.GetAsString(Value)));
      stString:
        Result := Self.GetConnection.GetEscapeString(SoftVarManager.GetAsString(Value));
      stUnicodeString:
        {$IFDEF DELPHI12_UP}
          Result := GetConnection.GetEscapeString(SoftVarManager.GetAsUnicodeString(Value));
        {$ELSE}
        if GetConnection.GetClientCodePageInformations^.Encoding = ceUTF8 then
          Result := Self.GetConnection.GetEscapeString(PAnsiChar(UTF8Encode(SoftVarManager.GetAsUnicodeString(Value))))
        else
          Result := Self.GetConnection.GetEscapeString(PAnsiChar(AnsiString(SoftVarManager.GetAsUnicodeString(Value))));
        {$ENDIF}
      stDate:
        Result := Format('''%s''::date',
          [FormatDateTime('yyyy-mm-dd', SoftVarManager.GetAsDateTime(Value))]);
      stTime:
        Result := Format('''%s''::time',
          [FormatDateTime('hh":"mm":"ss', SoftVarManager.GetAsDateTime(Value))]);
      stTimestamp:
        Result := Format('''%s''::timestamp',
          [FormatDateTime('yyyy-mm-dd hh":"mm":"ss',
            SoftVarManager.GetAsDateTime(Value))]);
      stAsciiStream, stUnicodeStream, stBinaryStream:
        begin
          TempBlob := DefVarManager.GetAsInterface(Value) as IZBlob;
          if not TempBlob.IsEmpty then
          begin
            if (Self.GetConnection.GetClientCodePageInformations^.Encoding = ceUTF8) and
              (InParamTypes[ParamIndex] in [stAsciiStream, stUnicodeStream]) then
            begin
              TempStreamIn := TempBlob.GetStream;
              TempStream := GetValidatedUnicodeStream(TempStreamIn);
              TempStreamIn.Free;
              TempBlob.SetStream(TempStream);
              TempStream.Free;
            end;
            case InParamTypes[ParamIndex] of
              stBinaryStream:
                if ((GetConnection as IZPostgreSQLConnection).IsOidAsBlob) or
                  StrToBoolDef(Info.Values['oidasblob'], False) then
                begin
                  TempStream := TempBlob.GetStream;
                  try
                    WriteTempBlob := TZPostgreSQLBlob.Create(FPlainDriver, nil, 0,
                      Self.GetConnectionHandle, 0, ChunkSize);
                    WriteTempBlob.SetStream(TempStream);
                    WriteTempBlob.WriteBlob;
                    Result := IntToStr(WriteTempBlob.GetBlobOid);
                  finally
                    WriteTempBlob := nil;
                    TempStream.Free;
                  end;
                end
                else
                  Result := GetConnection.GetEscapeString(TempBlob.GetString);
              stAsciiStream:
                {$IFDEF DELPHI12_UP}
                if (Self.GetConnection.GetClientCodePageInformations^.Encoding = ceUTF8) then
                  Result := GetConnection.GetEscapeString(TempBlob.GetUnicodeString)
                else
                {$ENDIF}
                  Result := GetConnection.GetEscapeString(String(TempBlob.GetString));
              stUnicodeStream:
                {$IFDEF DELPHI12_UP}
                  Result := GetConnection.GetEscapeString(TempBlob.GetUnicodeString);
                {$ELSE}
                  Result := GetConnection.GetEscapeString(TempBlob.GetString);
                {$ENDIF}
            end; {case..}
          end
          else
            Result := 'NULL';
        end; {if not TempBlob.IsEmpty then}
    end;
  end;
end;

{**
  Executes an SQL statement that returns a single <code>ResultSet</code> object.
  @param sql typically this is a static SQL <code>SELECT</code> statement
  @return a <code>ResultSet</code> object that contains the data produced by the
    given query; never <code>null</code>
}
function TZPostgreSQLCallableStatement.ExecuteQuery(
  const SQL: string): IZResultSet;
var
  QueryHandle: PZPostgreSQLResult;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  Result := nil;
  ConnectionHandle := GetConnectionHandle();
  Self.SSQL := SQL; //Preprepares the SQL and Sets the AnsiSQL
  QueryHandle := GetPlainDriver.ExecuteQuery(ConnectionHandle,
    PAnsiChar(ASQL));
  CheckPostgreSQLError(Connection, GetPlainDriver, ConnectionHandle, lcExecute,
    SQL, QueryHandle);
  DriverManager.LogMessage(lcExecute, GetPlainDriver.GetProtocol, SSQL);
  if QueryHandle <> nil then
  begin
    Result := CreateResultSet(SSQL, QueryHandle);
    FetchOutParams(Result);
  end
  else
    Result := nil;
end;

{**
  Prepares and executes an SQL statement that returns a single <code>ResultSet</code> object.
  @return a <code>ResultSet</code> object that contains the data produced by the
    given query; never <code>null</code>
}
function TZPostgreSQLCallableStatement.ExecuteQueryPrepared: IZResultSet;
Var SQL: String;
begin
  TrimInParameters;
  SQL := GetProcedureSql();
  SQL := FillParams(SQL);
  Result := Self.ExecuteQuery(SQL);
end;

{**
   Create sql string for calling stored procedure.
   @return a Stored Procedure SQL string
}
function TZPostgreSQLCallableStatement.GetProcedureSql: string;

  function GenerateParamsStr(Count: integer): string;
  var
    I: integer;
  begin
    Result := '';
    for I := 0 to Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + '?';
    end;
  end;

var
  InParams: string;
begin
  InParams := GenerateParamsStr(Length(InParamValues));
  Result := Format('SELECT * FROM %s(%s)', [SQL, InParams]);
end;

{**
   Fills the parameter (?) tokens with corresponding parameter value
   @return a prepared SQL query for execution
}
function TZPostgreSQLCallableStatement.FillParams(const ASql:String):String;
var I: Integer;
  Tokens: TStrings;
  ParamIndex: Integer;
begin
  if Pos('?', ASql) > 0 then
  begin
    Tokens := Connection.GetDriver.GetTokenizer.TokenizeBufferToList(ASql, [toUnifyWhitespaces]);
    try
      ParamIndex := 0;
      for I := 0 to Tokens.Count - 1 do
      begin
        if Tokens[I] = '?' then
        begin
          Tokens[I] := PrepareSQLParam(ParamIndex);
          Inc(ParamIndex);
        end
      end;
      Result := StringReplace(Tokens.Text, #13#10, ' ', [rfReplaceAll]);
    finally
      Tokens.Free;
    end;
  end
  else
    Result := ASql;
  //if GetConnection.PreprepareSQL then
    //Result := GetConnection.GetDriver.GetTokenizer.GetEscapeString(Result);
end;

{**
  Executes an SQL <code>INSERT</code>, <code>UPDATE</code> or
  <code>DELETE</code> statement. In addition,
  SQL statements that return nothing, such as SQL DDL statements,
  can be executed.

  @param sql an SQL <code>INSERT</code>, <code>UPDATE</code> or
    <code>DELETE</code> statement or an SQL statement that returns nothing
  @return either the row count for <code>INSERT</code>, <code>UPDATE</code>
    or <code>DELETE</code> statements, or 0 for SQL statements that return nothing
}
function TZPostgreSQLCallableStatement.ExecuteUpdate(const SQL: string): Integer;
var
  QueryHandle: PZPostgreSQLResult;
  ConnectionHandle: PZPostgreSQLConnect;
begin
  Result := -1;
  ConnectionHandle := GetConnectionHandle();
  Self.SSQL := SQL; //Preprepares the SQL and Sets the AnsiSQL
  QueryHandle := GetPlainDriver.ExecuteQuery(ConnectionHandle,
    PAnsiChar(ASQL));
  CheckPostgreSQLError(Connection, GetPlainDriver, ConnectionHandle, lcExecute,
    SSQL, QueryHandle);
  DriverManager.LogMessage(lcExecute, GetPlainDriver.GetProtocol, SSQL);

  if QueryHandle <> nil then
  begin
    Result := StrToIntDef(String(StrPas(GetPlainDriver.GetCommandTuples(QueryHandle))), 0);
    FetchOutParams(CreateResultSet(SSQL, QueryHandle));
  end;

  { Autocommit statement. }
  if Connection.GetAutoCommit then
    Connection.Commit;
end;


function TZPostgreSQLCallableStatement.ExecuteUpdatePrepared: Integer;
Var SQL: String;
begin
  TrimInParameters;
  SQL := GetProcedureSql();
  SQL := FillParams(SQL);
  Result := Self.ExecuteUpdate(SQL);
end;

{**
  Sets output parameters from a ResultSet
  @param Value a IZResultSet object.
}
procedure TZPostgreSQLCallableStatement.FetchOutParams(ResultSet: IZResultSet);
var
  ParamIndex, I: Integer;
  Temp: TZVariant;
  HasRows: Boolean;
begin
  ResultSet.BeforeFirst;
  HasRows := ResultSet.Next;

  I := 1;
  for ParamIndex := 0 to OutParamCount - 1 do
  begin
    if not (FDBParamTypes[ParamIndex] in [2, 3, 4]) then // ptOutput, ptInputOutput, ptResult
      Continue;

    if I > ResultSet.GetMetadata.GetColumnCount then
      Break;

    if (not HasRows) or (ResultSet.IsNull(I)) then
      DefVarManager.SetNull(Temp)
    else
      case ResultSet.GetMetadata.GetColumnType(I) of
      stBoolean:
        DefVarManager.SetAsBoolean(Temp, ResultSet.GetBoolean(I));
      stByte:
        DefVarManager.SetAsInteger(Temp, ResultSet.GetByte(I));
      stShort:
        DefVarManager.SetAsInteger(Temp, ResultSet.GetShort(I));
      stInteger:
        DefVarManager.SetAsInteger(Temp, ResultSet.GetInt(I));
      stLong:
        DefVarManager.SetAsInteger(Temp, ResultSet.GetLong(I));
      stFloat:
        DefVarManager.SetAsFloat(Temp, ResultSet.GetFloat(I));
      stDouble:
        DefVarManager.SetAsFloat(Temp, ResultSet.GetDouble(I));
      stBigDecimal:
        DefVarManager.SetAsFloat(Temp, ResultSet.GetBigDecimal(I));
      stString:
        DefVarManager.SetAsString(Temp, ResultSet.GetString(I));
      stUnicodeString:
        DefVarManager.SetAsUnicodeString(Temp, ResultSet.GetString(I));
      stDate:
        DefVarManager.SetAsDateTime(Temp, ResultSet.GetDate(I));
      stTime:
        DefVarManager.SetAsDateTime(Temp, ResultSet.GetTime(I));
      stTimestamp:
        DefVarManager.SetAsDateTime(Temp, ResultSet.GetTimestamp(I));
      end;
    OutParamValues[ParamIndex] := Temp;
    Inc(I);
  end;
  ResultSet.BeforeFirst;
end;

{**
   Function removes ptResult, ptOutput parameters from
   InParamTypes and InParamValues
}
procedure TZPostgreSQLCallableStatement.TrimInParameters;
var
  I: integer;
  ParamValues: TZVariantDynArray;
  ParamTypes: TZSQLTypeArray;
  ParamCount: Integer;
begin
  ParamCount := 0;
  SetLength(ParamValues, InParamCount);
  SetLength(ParamTypes, InParamCount);

  for I := 0 to High(InParamTypes) do
  begin
    if (Self.FDBParamTypes[i] in [2, 4]) then //[ptResult, ptOutput]
      Continue;
    ParamTypes[ParamCount] := InParamTypes[I];
    ParamValues[ParamCount] := InParamValues[I];
    Inc(ParamCount);
  end;

  if ParamCount = InParamCount then
    Exit;

  InParamTypes := ParamTypes;
  InParamValues := ParamValues;
  SetInParamCount(ParamCount);
end;

{ TZPostgreSQLCachedResolver }

{**
  Checks is the specified column can be used in where clause.
  @param ColumnIndex an index of the column.
  @returns <code>true</code> if column can be included into where clause.
}
function TZPostgreSQLCachedResolver.CheckKeyColumn(ColumnIndex: Integer): Boolean;
begin
  Result := (Metadata.GetTableName(ColumnIndex) <> '')
    and (Metadata.GetColumnName(ColumnIndex) <> '')
    and Metadata.IsSearchable(ColumnIndex)
    and not (Metadata.GetColumnType(ColumnIndex)
    in [stUnknown, stBinaryStream, stUnicodeStream]);
end;



end.

