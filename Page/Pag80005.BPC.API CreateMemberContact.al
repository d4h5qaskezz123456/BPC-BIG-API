page 80005 "BPC.API.Member Contact"
{
    PageType = API;
    Caption = 'apiCreateMemberContact';
    APIPublisher = 'bpc';
    APIGroup = 'apiMember';
    APIVersion = 'v2.0';
    EntityName = 'createMemberContact';
    EntitySetName = 'createMemberContacts';
    SourceTableTemporary = true;
    SourceTable = "BPC.TMP Member Contact";
    DelayedInsert = true;
    DeleteAllowed = false;
    ModifyAllowed = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupConnect)
            {
                field(id; rec.SystemId)
                {
                    Caption = 'id';
                    Editable = false;
                }
                // field(pTestConnect; pTestConnect)
                // {
                //     Caption = 'pTestConnect';
                //     trigger OnValidate()
                //     begin
                //         pTestConnect := FuncTestConnect;
                //     end;
                // }
                field(member_No; Rec."BPC Account No.")
                {
                    Caption = 'Account No.';
                }
                field(member_Name; rec."BPC Name")
                {
                    Caption = 'Name';
                }
                field(member_Address; Rec."BPC Address")
                {
                    Caption = 'Address';
                }
                field(member_City; Rec."BPC City")
                {
                    Caption = 'City';
                }
                field(member_PostCode; Rec."BPC Post Code")
                {
                    Caption = 'Post Code';
                }
                field(member_VATRegis; Rec."BPC VAT Registration No.")
                {
                    Caption = 'VAT Registration No.';
                }
                field(member_MPhoneNo; Rec."BPC Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                }
                field(member_PhoneNo; Rec."BPC Phone No.")
                {
                    Caption = 'Phone No.';
                }
                field(member_Email; Rec."BPC E-Mail")
                {
                    Caption = 'E-Mail';
                }
                field(member_BirthDate; Rec."BPC Date of Birth")
                {
                    Caption = 'Birthday';
                }
                field(member_Gender; rec."BPC Gender")
                {
                    Caption = 'Gender';
                }
                field(Status; Status)
                {
                    Caption = 'Return Status';
                }
                field(Result; Result)
                {
                    Caption = 'Return Result';
                }
            }
            // group(Control2)
            // {
            //     part(Member_Attention; "BPC.API.CreateMemberAttention")
            //     {
            //         Caption = 'apicreateMemberAttention';
            //         EntityName = 'member_Attentions';
            //         EntitySetName = 'member_Attention';
            //         SubPageLink = "BPC Member Account No." = field("BPC Account No.");
            //     }
            // }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        InsertData(Rec);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        InsertData(Rec);
        exit(false);
    end;

    local procedure InsertData(APIWeight: Record "BPC.TMP Member Contact" temporary)
    begin
        Clear(Result);
        Clear(Status);
        ClearLastError();
        LSCMemberAccount.Reset();
        LSCMemberAccount.SetRange("No.", APIWeight."BPC Account No.");
        if LSCMemberAccount.FindSet() then
            ResultText := 'Update'
        else
            ResultText := 'Create';

        if not Codeunit.Run(Codeunit::"BPC.Insert Member", APIWeight) then begin
            Status := 'UNSUCCESS.';
            Result := StrSubstNo('Error : ' + GETLASTERRORTEXT);
            CreateAPILog(RecAPILog, UserId, 1, 'Create Member Account', Result);
        end else begin
            Status := 'SUCCESS.';
            Result := StrSubstNo('%1 : Member %2 Success.', ResultText, APIWeight."BPC Account No.");
            CreateAPILog(RecAPILog, UserId, 0, 'Create Member Account', Result);
        end;

    end;

    procedure CreateAPILog(var APILog: Record "BPC.API Log Member Contact"; EmployeeNo: Code[20]; Status: Option Success,Error; MethodName: Text[100]; Description: text[1000])
    begin
        APILog.InitEnty(MethodName, Description, EmployeeNo, Status);
        LastEntryNo := APILog.GetNextEntryNo();
        APILog."Entry No." := LastEntryNo;
        APILog.Insert();
    end;

    local procedure FuncTestConnect(): Text
    begin
        EXIT(STRSUBSTNO('%1 : Connect Success.', pTestConnect));
    end;

    var
        pTestConnect: Text;

    var
        LSCMemberAccount: Record "LSC Member Account";
        LastEntryNo: Integer;
        ResultText: Text;
        Result: Text;
        status: Text;
        RecAPILog: Record "BPC.API Log Member Contact";
}