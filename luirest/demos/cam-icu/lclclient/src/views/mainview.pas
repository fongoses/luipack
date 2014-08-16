unit MainView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Grids, JvXPBar, VTJSON, MainPresenter, fpjson, VirtualTrees;

type

  { TMainForm }

  TMainForm = class(TForm, IFPObserver)
    PatientBar: TJvXPBar;
    PatientListView: TVirtualJSONListView;
    procedure PatientBarEvaluationsClick(Sender: TObject);
    procedure PatientListViewFocusChanged(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Column: TColumnIndex);
    procedure PatientListViewGetText(Sender: TCustomVirtualJSONDataView;
      Node: PVirtualNode; NodeData: TJSONData; Column: TColumnIndex;
      TextType: TVSTTextType; var CellText: String);
  private
    FPresenter: TMainPresenter;
    procedure FPOObservedChanged(ASender: TObject;
      Operation: TFPObservedOperation; Data: Pointer);
    procedure PatientSelectedChange(Sender: TObject);
    procedure SetPresenter(Value: TMainPresenter);
    procedure UpdatePatientSelection;
  public
  published
    property Presenter: TMainPresenter read FPresenter write SetPresenter;
  end;

var
  MainForm: TMainForm;

implementation

uses
  LuiJSONUtils;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.PatientListViewFocusChanged(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex);
var
  NodeData: TJSONObject;
begin
  PatientListView.GetData(Node, NodeData);
  FPresenter.SelectedPatientData := NodeData;
end;

procedure TMainForm.PatientListViewGetText(Sender: TCustomVirtualJSONDataView;
  Node: PVirtualNode; NodeData: TJSONData; Column: TColumnIndex;
  TextType: TVSTTextType; var CellText: String);
const
  PropNames: array[2..4] of String = ('birthdate', 'internmentdate', 'dischargedate');
var
  NodeObjData: TJSONObject absolute NodeData;
  ADate: TDateTime;
begin
  case Column of
    2, 3, 4:
      begin
        if FindJSONProp(NodeObjData, PropNames[Column], ADate) then
          CellText := DateToStr(ADate);
      end;
  end;
end;

procedure TMainForm.PatientBarEvaluationsClick(Sender: TObject);
begin
  FPresenter.ShowPatientEvaluations;
end;

procedure TMainForm.FPOObservedChanged(ASender: TObject;
  Operation: TFPObservedOperation; Data: Pointer);
begin
  if ASender = FPresenter.Patients then
  begin
    case Operation of
      ooChange, ooAddItem, ooDeleteItem:
        begin
          if (Data = nil) or (Operation in [ooAddItem, ooDeleteItem]) then
          begin
            PatientListView.Data := FPresenter.Patients.Data;
            PatientListView.LoadData;
            UpdatePatientSelection;
          end
          else
            PatientListView.Invalidate;
        end;
    end;
  end;
end;

procedure TMainForm.PatientSelectedChange(Sender: TObject);
begin
  UpdatePatientSelection;
end;

procedure TMainForm.SetPresenter(Value: TMainPresenter);
begin
  FPresenter := Value;
  FPresenter.Patients.FPOAttachObserver(Self);
  FPresenter.OnSelectedPatientChange := @PatientSelectedChange;
end;

procedure TMainForm.UpdatePatientSelection;
begin
  PatientListView.FocusedNode := PatientListView.GetNode(FPresenter.SelectedPatientData);
  PatientListView.Selected[PatientListView.FocusedNode] := True;
  if FPresenter.SelectedPatientData <> nil then
    PatientBar.Caption := FPresenter.SelectedPatientData.Get('name', '')
  else
    PatientBar.Caption := '';
end;

end.
