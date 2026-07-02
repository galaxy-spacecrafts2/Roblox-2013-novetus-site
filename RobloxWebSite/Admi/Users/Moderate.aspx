<%@ Page Title="" Language="C#" MasterPageFile="~/Admi/AdmiSimple.Master" AutoEventWireup="true" CodeBehind="Moderate.aspx.cs" Inherits="Roblox.Website.Admi.Users.Moderate" %>
<%-- <%@ Register assembly="Roblox.Controls" namespace="Roblox.Controls" tagprefix="rbx" %> --%>

<asp:Content ID="Content1" ContentPlaceHolderID="cphRoblox" runat="server">
    <div style="margin: 0 auto 0 auto; width: 600px">
        <%-- This page has never seen the light of day, so here are some specifications for what I'd like to have done with it when the time comes... --%>
        <asp:Panel ID="SpecificationsPanel"
            BackColor="LightSteelBlue"
            BorderColor="LightSteelBlue"
            ForeColor="White"
            runat="server">
            <h3 style="background-color: SteelBlue; color: White;">Specifications</h3>
            <h4>This page should contain the following:</h4>
            <ul>
                <li>User name, user ID, basic user info.</li>
                <li>UserBlurb/Description, UserStatus.</li>
                <li>Recently modified Assets (this includes recently created Assets, we'll sort by Updated)</li>
                <li>All places (including their statuses)</li>
                <li>Hyper-links to payments, transactions on-site, trades, messages, IP addresses, MAC addresses</li>
                <li>Moderation card + cheat detections & past punishments (essentially bottom-half of ModerateUser.aspx)</li>
                <li>Pretty much a hotspot for any user-generated content for the user with the given ID in the request query</li>
            </ul>
        </asp:Panel>
    </div>
</asp:Content>
