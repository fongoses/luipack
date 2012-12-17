unit XMLServiceView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ExtCtrls, StdCtrls, Grids,
  AddressBookClient, Dialogs, XMLRead, DOM;

type

  { TXMLServiceViewFrame }

  TXMLServiceViewFrame = class(TFrame)
    AddContactButton: TButton;
    AddPhoneButton: TButton;
    BaseURLEdit: TLabeledEdit;
    ContactsGrid: TStringGrid;
    DeleteContactButton: TButton;
    DeletePhoneButton: TButton;
    EditContactButton: TButton;
    EditPhoneButton: TButton;
    Label1: TLabel;
    LoadDataButton: TButton;
    PhonesGrid: TStringGrid;
    PhonesLabel: TLabel;
    procedure AddContactButtonClick(Sender: TObject);
    procedure AddPhoneButtonClick(Sender: TObject);
    procedure ContactsGridSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure DeleteContactButtonClick(Sender: TObject);
    procedure DeletePhoneButtonClick(Sender: TObject);
    procedure EditContactButtonClick(Sender: TObject);
    procedure EditPhoneButtonClick(Sender: TObject);
    procedure LoadDataButtonClick(Sender: TObject);
  private
    FContacts: TXMLDocument;
    FContactPhones: TXMLDocument;
    FRESTClient: TAddressBookRESTClient;
    procedure ResponseError(ResourceTag: PtrInt; Method: THTTPMethodType;
      ResponseCode: Integer; ResponseStream: TStream);
    procedure ResponseSuccess(ResourceTag: PtrInt; Method: THTTPMethodType;
      ResponseCode: Integer; ResponseStream: TStream);
    procedure SocketError(Sender: TObject; ErrorCode: Integer;
      const ErrorDescription: String);
    procedure ShowNotImplemented;
    procedure UpdateContactPhones(ContactNode: TDOMNode);
    procedure UpdateContactsView;
    procedure UpdatePhonesView;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.lfm}

procedure TXMLServiceViewFrame.ContactsGridSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
var
  ContactNode, ResponseNode: TDOMNode;
begin
  if FContacts = nil then
    Exit;
  ResponseNode := FContacts.FindNode('response');
  if (aRow > 0) and (ResponseNode <> nil) and (aRow <= ResponseNode.ChildNodes.Count) then
  begin
    ContactNode := ResponseNode.ChildNodes.Item[aRow - 1];
    UpdateContactPhones(ContactNode);
  end;
end;

procedure TXMLServiceViewFrame.DeleteContactButtonClick(Sender: TObject);
begin
  ShowNotImplemented;
end;

procedure TXMLServiceViewFrame.DeletePhoneButtonClick(Sender: TObject);
begin
  ShowNotImplemented;
end;

procedure TXMLServiceViewFrame.EditContactButtonClick(Sender: TObject);
begin
  ShowNotImplemented;
end;

procedure TXMLServiceViewFrame.EditPhoneButtonClick(Sender: TObject);
begin
  ShowNotImplemented;
end;

procedure TXMLServiceViewFrame.AddContactButtonClick(Sender: TObject);
begin
  ShowNotImplemented;
end;

procedure TXMLServiceViewFrame.AddPhoneButtonClick(Sender: TObject);
begin
  ShowNotImplemented;
end;

procedure TXMLServiceViewFrame.LoadDataButtonClick(Sender: TObject);
begin
  FRESTClient.BaseURL := BaseURLEdit.Text;
  FRESTClient.Get('contacts?format=xml', RES_CONTACTS);
end;

procedure TXMLServiceViewFrame.ResponseSuccess(ResourceTag: PtrInt; Method: THTTPMethodType;
  ResponseCode: Integer; ResponseStream: TStream);
var
  ResponseDoc: TXMLDocument;
begin
  case ResourceTag of
    RES_CONTACTS:
      begin
        case Method of
          hmtGet:
          begin
            ReadXMLFile(ResponseDoc, ResponseStream);
            if ResponseDoc <> nil then
            begin
              FContacts.Free;
              FContacts := ResponseDoc;
              UpdateContactsView;
            end;
          end;
          hmtPost:
          begin
            //not implemented
          end;
        end;
      end;
    RES_CONTACT:
      begin
        case Method of
          hmtPut:
          begin
            //not implemented
          end;
        end;
      end;
    RES_CONTACTPHONES:
      begin
        case Method of
          hmtGet:
          begin
            ReadXMLFile(ResponseDoc, ResponseStream);
            if ResponseDoc <> nil then
            begin
              FContactPhones.Free;
              FContactPhones := ResponseDoc;
              UpdatePhonesView;
            end;
          end;
          hmtPost:
          begin
            //not implemented
          end;
        end;
      end;
    RES_CONTACTPHONE:
      begin
        case Method of
          hmtPut:
          begin
            //not implemented
          end;
        end;
      end;
  end;
end;

procedure TXMLServiceViewFrame.ResponseError(ResourceTag: PtrInt; Method: THTTPMethodType;
  ResponseCode: Integer; ResponseStream: TStream);
var
  ResponseDoc: TXMLDocument;
  ResponseNode, MessageNode: TDOMNode;
  Message: String;
begin
  ReadXMLFile(ResponseDoc, ResponseStream);
  if ResponseDoc <> nil then
  begin
    ResponseNode := ResponseDoc.FindNode('response');
    if ResponseNode <> nil then
    begin
      MessageNode := ResponseNode.FindNode('message');
      if MessageNode <> nil then
        Message := MessageNode.FirstChild.NodeValue;
    end;
    if Message <> '' then
      Message := LineEnding + Message;
  end;
  ShowMessageFmt('Server response error%s', [Message]);
  ResponseDoc.Free;
end;

procedure TXMLServiceViewFrame.SocketError(Sender: TObject; ErrorCode: Integer;
  const ErrorDescription: String);
begin
  ShowMessageFmt('Socket Error: "%s"', [ErrorDescription]);
end;

procedure TXMLServiceViewFrame.ShowNotImplemented;
begin
  ShowMessage('Not implemented' + LineEnding + 'No time/interest to implement writeable XML service');
end;

procedure TXMLServiceViewFrame.UpdateContactsView;
var
  ContactNode: TDOMNode;
  i: Integer;
begin
  ContactsGrid.RowCount := FContacts.DocumentElement.ChildNodes.Count + 1;
  ContactNode := FContacts.DocumentElement.FirstChild;
  i := 1;
  while ContactNode <> nil do
  begin
    ContactsGrid.Cells[0, i] := ContactNode.FindNode('Id').FirstChild.NodeValue;
    ContactsGrid.Cells[1, i] := ContactNode.FindNode('Name').FirstChild.NodeValue;
    Inc(i);
    ContactNode := ContactNode.NextSibling;
  end;
end;

procedure TXMLServiceViewFrame.UpdateContactPhones(ContactNode: TDOMNode);
var
  ResourcePath: String;
  IdNode, NameNode: TDOMNode;
begin
  if ContactNode = nil then
    Exit;
  NameNode := ContactNode.FindNode('Name');
  if NameNode <> nil then
    PhonesLabel.Caption := NameNode.FirstChild.NodeValue + ' Phones';
  IdNode := ContactNode.FindNode('Id');
  if IdNode <> nil then
  begin
    ResourcePath := Format('contacts/%s/phones?format=xml', [IdNode.FirstChild.NodeValue]);
    FRESTClient.Get(ResourcePath, RES_CONTACTPHONES);
  end;
end;

procedure TXMLServiceViewFrame.UpdatePhonesView;
var
  PhoneNode, ResponseNode: TDOMNode;
  i: Integer;
begin
  ResponseNode := FContactPhones.FindNode('response');
  if ResponseNode <> nil then
  begin
    PhonesGrid.RowCount := ResponseNode.ChildNodes.Count + 1;
    PhoneNode := ResponseNode.FirstChild;
    i := 1;
    while PhoneNode <> nil do
    begin
      PhonesGrid.Cells[0, i] := PhoneNode.FindNode('Id').FirstChild.NodeValue;
      PhonesGrid.Cells[1, i] := PhoneNode.FindNode('Number').FirstChild.NodeValue;
      Inc(i);
      PhoneNode := PhoneNode.NextSibling;
    end;
  end;
end;

constructor TXMLServiceViewFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FRESTClient := TAddressBookRESTClient.Create(Self);
  FRESTClient.OnResponseSuccess := @ResponseSuccess;
  FRESTClient.OnResponseError := @ResponseError;
  FRESTClient.OnSocketError := @SocketError;
end;

destructor TXMLServiceViewFrame.Destroy;
begin
  FContacts.Free;
  FContactPhones.Free;
  inherited Destroy;
end;


end.

