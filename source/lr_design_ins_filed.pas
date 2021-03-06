unit lr_design_ins_filed;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, Forms, Controls, ExtCtrls, StdCtrls, Buttons, ComCtrls,
  IniFiles, LazFileUtils, TreeFilterEdit, LR_Ev_ed,
  LR_Class, Dialogs;

type

  { TlrFieldsList }

  TlrFieldsList = class(TFrame)
    btnPlus: TSpeedButton;
    btnVariables: TSpeedButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    HeaderCB: TCheckBox;
    fPanelHeader: TPanel;
    ImgDataset: TImageList;
    ImgVars: TImageList;
    PageControl1: TPageControl;
    SortCB: TCheckBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    btnMinius: TSpeedButton;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TreeDB: TTreeView;
    TreeFilterEdit4: TTreeFilterEdit;
    TreeFilterEdit5: TTreeFilterEdit;
    TreeVars: TTreeView;
    procedure btnMiniusClick(Sender: TObject);
    procedure btnPlusClick(Sender: TObject);
    procedure btnVariablesClick(Sender: TObject);
    procedure fPanelHeaderMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure fPanelHeaderMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure fPanelHeaderMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SortCBChange(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
  private
    fDown         : Boolean;
    fPt           : TPoint;
    FLastHeight:integer;
    procedure RestorePos;
    procedure SavePos;
    function IniFileName:string;
  public
    constructor Create(aOwner : TComponent); override;
    destructor Destroy; override;
    procedure RefreshDSList;
    procedure FillValCombo;
    function SelectedField:string;
    function SelectedText : String;
  end;

var
  lrFieldsList:TlrFieldsList = nil;

implementation
uses LR_Utils, LR_DBRel, LR_Desgn, LR_Const;

{$R *.lfm}

{ TlrFieldsList }

procedure TlrFieldsList.fPanelHeaderMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
  begin
    fDown:=True;
    if (x>4) and (x<fPanelHeader.Width-4) and (y<=16) then
    begin
      fPanelHeader.Cursor:=crSize;
      fPt:=Mouse.CursorPos;
    end;
  end;
end;

procedure TlrFieldsList.btnMiniusClick(Sender: TObject);
begin
  TreeDB.FullCollapse;
  btnPlus.Visible:= True;
  btnMinius.Visible:= False;
  TreeDB.Refresh;
end;

procedure TlrFieldsList.btnPlusClick(Sender: TObject);
begin
  TreeDB.FullExpand;
  btnMinius.Visible:= True;
  btnPlus.Visible:= False;
  TreeDB.Refresh;
end;

procedure TlrFieldsList.btnVariablesClick(Sender: TObject);
begin

end;

procedure TlrFieldsList.fPanelHeaderMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  NewPt: TPoint;
begin
  if fDown then
  begin
    Case fPanelHeader.Cursor of
      crSize :
        begin
          NewPt:=Mouse.CursorPos;
          SetBounds(Left+NewPt.X-fPt.X,Top+NewPt.Y-fPt.Y,Width,Height);
          fPt:=NewPt;
        end;
    end;
  end
end;

procedure TlrFieldsList.fPanelHeaderMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  fDown:=False;
  fPanelHeader.Cursor:=crDefault;
end;

procedure TlrFieldsList.SortCBChange(Sender: TObject);
begin
  with TreeDB do begin
    if SortCB.Checked then
       SortType  := stText
    else
      begin
        SortType  := stNone;
         RefreshDSList;
      end;
    Refresh;
  end;
end;

procedure TlrFieldsList.SpeedButton1Click(Sender: TObject);
begin
  if SpeedButton1.Caption='-' then
  begin
    FLastHeight:=Height;
    Height:=fPanelHeader.Height + 2*BorderWidth + 3;
    SpeedButton1.Caption:='+';
  end
  else
  begin
    Height:=FLastHeight;
    SpeedButton1.Caption:='-';
  end;
end;

procedure TlrFieldsList.SpeedButton2Click(Sender: TObject);
begin
  TfrDesignerForm(frDesigner).tlsDBFields.Checked:=false;
  Application.ReleaseComponent(Self);
end;

procedure TlrFieldsList.RestorePos;
var
  Ini:TIniFile;
begin
  if FileExistsUTF8(IniFileName) then
  begin
    Ini:=TIniFile.Create(IniFileName);
    Left:=Ini.ReadInteger('Position', 'Left', Left);
    Top:=Ini.ReadInteger('Position', 'Top', Top);
    Height:=Ini.ReadInteger('Position', 'Height', Height);
    Width:=Ini.ReadInteger('Position', 'Width', Width);
    Ini.Free;
  end;
end;

procedure TlrFieldsList.SavePos;
var
  Ini:TIniFile;
begin
  Ini:=TIniFile.Create(IniFileName);
  Ini.WriteInteger('Position', 'Left', Left);
  Ini.WriteInteger('Position', 'Top', Top);
  if SpeedButton1.Caption = '+' then
    Ini.WriteInteger('Position', 'Height', FLastHeight)
  else
    Ini.WriteInteger('Position', 'Height', Height);
  Ini.WriteInteger('Position', 'Width', Width);
  Ini.Free;
end;

function TlrFieldsList.IniFileName: string;
begin
  Result:=AppendPathDelim(lrConfigFolderName(false))+'lrFieldsList.cfg';
end;

procedure TlrFieldsList.FillValCombo;
var
  s: TStringList;
  i : Integer = 0;
  x : Integer = 0;
  ts : TStringList;
  z  : Integer = 0;
  v  : Integer = 0;
begin
  s := TStringList.Create;
  ts := TStringList.Create;
  CurReport.GetCategoryList(s);
  s.Add(sSpecVal);
  s.Add(sFRVariables);
  with TreeVars.Items do
    begin
      Clear;
      AddFirst(nil,sVarFormCapt);  //Nodo principal
      Item[0].ImageIndex:= 0;    // Imagen del nodo
      if s.Count > 0 then begin
         for i := 0 to s.Count-1 do // Nodos hijos
           AddChild(Item[0],s.Strings[i]);
         {Se agregan o cargan las variables}
         for i := 0 to Pred(Item[0].Count) do begin
           with Item[0] do begin
              Items[i].ImageIndex:= 1;
             if Items[i].Text = sFRVariables then begin
                  for x := 0 to Pred(frVariables.Count) do
                    AddChild(Items[i],frVariables.Name[x]);
                end
              else if Items[i].Text = sSpecVal then begin
                    x := 0;
                    for x := 0 to (frSpecCount-1) do begin
                      if x <> 1 then
                        AddChild(Items[i],frSpecArr[x]);
                    end;
                  end
              else
                begin
                   ts.Clear;
                   CurReport.GetVarList(i, ts);
                   x := 0;
                   for x := 0 to Pred(ts.Count) do
                     AddChild(Items[i],ts.Strings[x]);
                end;
            end;
         end;
      end;
    end;
  ts.Free;
  s.Free;
end;


constructor TlrFieldsList.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  RestorePos;
  RefreshDSList;
  FillValCombo;
  fPanelHeader.Caption := sFRDesignerDataInsp;
  HeaderCB.Caption     := sInsertFieldsFormHeader;
  btnVariables.Hint    := sEvFormCapt;
end;

destructor TlrFieldsList.Destroy;
begin
  SavePos;
  lrFieldsList:=nil;
  inherited Destroy;
end;

procedure TlrFieldsList.RefreshDSList;
var
  Lst : TStringList;
  i   : Integer = 0;
  x   : Integer = 0;
  z   : Integer = 4;
  c   : String;
  DataSet : TDataSet;
begin
  Lst := TStringList.Create;
  try
    if CurReport.DataType = dtDataSet then
      frGetComponents(CurReport.Owner, TDataSet, Lst, nil)
    else
      frGetComponents(CurReport.Owner, TDataSource, Lst, nil);

    with TreeDB.Items do
    begin
      Clear;
      AddFirst(nil,sVBandEditorFormDataSource);  //Nodo principal
      Item[0].ImageIndex:= 0;    // Imagen del nodo
      if Lst.Count > 0 then begin
         for i := 0 to Pred(Lst.Count) do // Nodos hijos
           AddChildFirst(Item[0],Lst.Strings[i]);
         {Se agregan los campos o filas a cada dataset}
         for i := 0 to Pred(Item[0].Count) do begin
           with Item[0] do begin
              Items[i].ImageIndex:= 1;
              DataSet := frGetDataSet(Items[i].Text);
              if Assigned(DataSet) then begin
                try
                  if DataSet.FieldCount = 0 then
                      DataSet.Opening;

                  for x := 0 to Pred(DataSet.FieldCount) do begin
                    AddChild(Items[i],DataSet.FieldDefs[x].Name);
                    case Dataset.FieldDefs[x].DataType of
                      ftBoolean : z := 8;
                      ftAutoInc : z := 2;
                      ftFloat   : z := 13;
                      ftCurrency: z := 11;
                      ftDate    : z := 7;
                      ftTime,ftDateTime,ftTimeStamp   : z := 6;
                      ftMemo,ftBytes,ftFmtMemo,ftOraBlob,ftBlob : z := 9;
                      ftGraphic                                 : z := 10;
                      ftInteger                                 : z := 5;
                    else
                      z := 4;
                    end;
                    Items[i].Items[x].ImageIndex:= z;
                  end;

                  if DataSet.Active then
                     DataSet.ForceClose;
                except
                end;
              end;
            end;
         end;
      end;
    end;
    TreeDB.Enabled:= (Lst.Count>0);
  finally
    Lst.Free;
  end;
end;

function TlrFieldsList.SelectedField: string;
var
  node   : TTreeNode;
  i : Integer;
begin
  i := PageControl1.ActivePageIndex;
  Result:= '' ;
  if i = 0 then
  begin
    if (TreeDB.Items.Count > 0) and (TreeDB.Selected.Selected) then
    begin
      node :=TreeDB.Items.FindNodeWithText(TreeDB.Selected.Text);
      if node.Count = 0 then
         Result := node.Parent.Text+'."'+TreeDB.Selected.Text+'"'
      else
        Result  := sNotAssigned;
    end
   end
  else
    begin
     if (TreeVars.Items.Count > 0) and (TreeVars.Selected.Selected) then
      begin
        node :=TreeVars.Items.FindNodeWithText(TreeVars.Selected.Text);
        if node.Count = 0 then
         begin
            if node.Parent.Text <> sSpecVal then
              Result := TreeVars.Selected.Text
            else if TreeVars.Selected.Index > 0 then
              Result := frSpecFuncs[TreeVars.Selected.Index+1]
            else
              Result  := frSpecFuncs[0];
          end;
        end;
    end;
end;

function TlrFieldsList.SelectedText: String;
var
  node : TTreeNode;
begin
   Result:='';
  if PageControl1.ActivePageIndex = 0 then
    if (TreeDB.Items.Count > 0) and (TreeDB.Selected.Selected) then begin
      node :=TreeDB.Items.FindNodeWithText(TreeDB.Selected.Text);
      if node.Count = 0 then
         Result := TreeDB.Selected.Text
      else
        Result  := sNotAssigned;
   end
  else
    Result      := sNotAssigned;
  Result        := UpperCase(Result);
end;

end.
