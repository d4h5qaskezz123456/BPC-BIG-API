page 80006 "BPC.API.CreateMemberAttention"
{
    PageType = API;
    Caption = 'apicreateMemberAttention';
    APIPublisher = 'bpc';
    APIGroup = 'apiMember';
    APIVersion = 'v2.0';
    EntityName = 'member_Attentions';
    EntitySetName = 'member_Attention';
    SourceTable = "BPC.Member Attention";
    DelayedInsert = true;
    DeleteAllowed = false;
    ModifyAllowed = true;
    SourceTableTemporary = true;
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

                field(Atten_1; rec."BPC Atten_1")
                {
                    Caption = 'Atten_1';
                }
                field(Atten_2; Rec."BPC Atten_2")
                {
                    Caption = 'Atten_2';
                }
                field(Atten_3; Rec."BPC Atten_3")
                {
                    Caption = 'Atten_3';
                }
                field(Atten_4; rec."BPC Atten_4")
                {
                    Caption = 'Atten_4';
                }
                field(Atten_5; Rec."BPC Atten_5")
                {
                    Caption = 'Atten_5';
                }
                field(Atten_6; Rec."BPC Atten_6")
                {
                    Caption = 'Atten_6';
                }
                field(Atten_7; rec."BPC Atten_7")
                {
                    Caption = 'Atten_7';
                }
                field(Atten_8; Rec."BPC Atten_8")
                {
                    Caption = 'Atten_8';
                }
                field(Atten_9; Rec."BPC Atten_9")
                {
                    Caption = 'Atten_9';
                }
                field(Atten_10; rec."BPC Atten_10")
                {
                    Caption = 'Atten_10';
                }
            }
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

    local procedure InsertData(APITMPMemberContact: Record "BPC.Member Attention" temporary)
    var
        MemberAttention: Record "BPC.Member Attention";
    begin

        if APITMPMemberContact."BPC Atten_1" <> '' then begin
            if not MemberAttention.Get(APITMPMemberContact."BPC Member Account No.", 'Atten1') then begin
                MemberAttention.Init();
                MemberAttention."BPC Member Account No." := APITMPMemberContact."BPC Member Account No.";
                MemberAttention."BPC Attention ID" := 'Atten1';
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_1";
                MemberAttention.Insert();
            end else begin
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_1";
                MemberAttention.Modify();
            end;
        end;

        if APITMPMemberContact."BPC Atten_2" <> '' then begin
            if not MemberAttention.Get(APITMPMemberContact."BPC Member Account No.", 'Atten2') then begin
                MemberAttention.Init();
                MemberAttention."BPC Member Account No." := APITMPMemberContact."BPC Member Account No.";
                MemberAttention."BPC Attention ID" := 'Atten2';
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_2";
                MemberAttention.Insert();
            end else begin
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_2";
                MemberAttention.Modify();
            end;
        end;
        if APITMPMemberContact."BPC Atten_3" <> '' then begin
            if not MemberAttention.Get(APITMPMemberContact."BPC Member Account No.", 'Atten3') then begin
                MemberAttention.Init();
                MemberAttention."BPC Member Account No." := APITMPMemberContact."BPC Member Account No.";
                MemberAttention."BPC Attention ID" := 'Atten3';
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_3";
                MemberAttention.Insert();
            end else begin
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_3";
                MemberAttention.Modify();
            end;
        end;
        if APITMPMemberContact."BPC Atten_4" <> '' then begin
            if not MemberAttention.Get(APITMPMemberContact."BPC Member Account No.", 'Atten4') then begin
                MemberAttention.Init();
                MemberAttention."BPC Member Account No." := APITMPMemberContact."BPC Member Account No.";
                MemberAttention."BPC Attention ID" := 'Atten4';
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_4";
                MemberAttention.Insert();
            end else begin
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_4";
                MemberAttention.Modify();
            end;
        end;
        if APITMPMemberContact."BPC Atten_5" <> '' then begin
            if not MemberAttention.Get(APITMPMemberContact."BPC Member Account No.", 'Atten5') then begin
                MemberAttention.Init();
                MemberAttention."BPC Member Account No." := APITMPMemberContact."BPC Member Account No.";
                MemberAttention."BPC Attention ID" := 'Atten5';
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_5";
                MemberAttention.Insert();
            end else begin
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_5";
                MemberAttention.Modify();
            end;
        end;
        if APITMPMemberContact."BPC Atten_6" <> '' then begin
            if not MemberAttention.Get(APITMPMemberContact."BPC Member Account No.", 'Atten6') then begin
                MemberAttention.Init();
                MemberAttention."BPC Member Account No." := APITMPMemberContact."BPC Member Account No.";
                MemberAttention."BPC Attention ID" := 'Atten6';
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_6";
                MemberAttention.Insert();
            end else begin
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_6";
                MemberAttention.Modify();
            end;
        end;
        if APITMPMemberContact."BPC Atten_7" <> '' then begin
            if not MemberAttention.Get(APITMPMemberContact."BPC Member Account No.", 'Atten7') then begin
                MemberAttention.Init();
                MemberAttention."BPC Member Account No." := APITMPMemberContact."BPC Member Account No.";
                MemberAttention."BPC Attention ID" := 'Atten7';
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_7";
                MemberAttention.Insert();
            end else begin
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_7";
                MemberAttention.Modify();
            end;
        end;
        if APITMPMemberContact."BPC Atten_8" <> '' then begin
            if not MemberAttention.Get(APITMPMemberContact."BPC Member Account No.", 'Atten8') then begin
                MemberAttention.Init();
                MemberAttention."BPC Member Account No." := APITMPMemberContact."BPC Member Account No.";
                MemberAttention."BPC Attention ID" := 'Atten8';
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_8";
                MemberAttention.Insert();
            end else begin
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_8";
                MemberAttention.Modify();
            end;
        end;
        if APITMPMemberContact."BPC Atten_9" <> '' then begin
            if not MemberAttention.Get(APITMPMemberContact."BPC Member Account No.", 'Atten9') then begin
                MemberAttention.Init();
                MemberAttention."BPC Member Account No." := APITMPMemberContact."BPC Member Account No.";
                MemberAttention."BPC Attention ID" := 'Atten9';
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_9";
                MemberAttention.Insert();
            end else begin
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_9";
                MemberAttention.Modify();
            end;
        end;
        if APITMPMemberContact."BPC Atten_10" <> '' then begin
            if not MemberAttention.Get(APITMPMemberContact."BPC Member Account No.", 'Atten10') then begin
                MemberAttention.Init();
                MemberAttention."BPC Member Account No." := APITMPMemberContact."BPC Member Account No.";
                MemberAttention."BPC Attention ID" := 'Atten10';
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_10";
                MemberAttention.Insert();
            end else begin
                MemberAttention."BPC Attention Text" := APITMPMemberContact."BPC Atten_10";
                MemberAttention.Modify();
            end;
        end;


    end;

    var
        pTestConnect: Text;
}