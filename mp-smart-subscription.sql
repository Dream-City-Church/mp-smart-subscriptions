USE [MinistryPlatform]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[service_dcc_smart_subscriptions]

	@DomainID INT

	AS

/****************************************************
***               Smart Subscriptions             ***
*****************************************************
A custom Dream City Church procedure for Ministry Platform
Version: 1.1
Author: Stephan Swinford
Date: 06/22/2023

This procedure is provided "as is" with no warranties expressed or implied.

-- Description --
Smartly subscribes people to Publications based on recent activity.

REQUIRES additional "Publication_ID" column added to the
Congregations, Ministries, and Events tables

*****************************************************
****************** BEGIN PROCEDURE ******************
*****************************************************/

/*** Set the Publication ID to subscribe anyone to with any activity ***/
DECLARE @PrimaryPublicationID INT;
SET @PrimaryPublicationID = /*** Publication ID that you want everyone to be subscribed to (e.g. News & Announcements) ***/;

/*** Create temporary tables for storing changes ***/
CREATE TABLE #CPInserted1 (Contact_Publication_ID INT)
CREATE TABLE #CPUnsubbed1 (Contact_Publication_ID INT)
CREATE TABLE #CPAuditDetail1 (Audit_Item_ID INT, Record_ID INT)

/** General News & Announcements Subscription **/
INSERT INTO dp_Contact_Publications(Contact_ID,Publication_ID,Unsubscribed,Domain_ID)
OUTPUT INSERTED.Contact_Publication_ID
INTO #CPInserted1
SELECT DISTINCT C.Contact_ID,@PrimaryPublicationId,0,@DomainID
FROM Contacts C
	LEFT JOIN Participants P ON P.Contact_ID = C.Contact_ID
	LEFT JOIN Activity_Log AL ON AL.Contact_ID = C.Contact_ID
WHERE
	AL.Activity_Date >= GetDate()-7
	AND ISNULL(C.__Age,18) >= 18
	AND C.Email_Address IS NOT NULL
	AND C.Bulk_Email_Opt_Out <> 1
	AND ISNULL(P.Participant_Type_ID,28) IN (28,31,36,52,83)
	AND NOT EXISTS(SELECT * FROM dp_Contact_Publications CP
		WHERE CP.Contact_ID=C.Contact_ID
		AND CP.Publication_ID=@PrimaryPublicationID)

/** Campus Smart Subscriptions **/
INSERT INTO dp_Contact_Publications(Contact_ID,Publication_ID,Unsubscribed,Domain_ID)
OUTPUT INSERTED.Contact_Publication_ID
INTO #CPInserted1
SELECT DISTINCT C.Contact_ID,CON.Publication_ID,0,@DomainID
FROM Contacts C
	LEFT JOIN Households H ON H.Household_ID = C.Household_ID
	LEFT JOIN Congregations CON ON CON.Congregation_ID = H.Congregation_ID
	LEFT JOIN Participants P ON P.Contact_ID = C.Contact_ID
	LEFT JOIN Activity_Log AL ON AL.Contact_ID = C.Contact_ID
WHERE
	AL.Congregation_ID=CON.Congregation_ID
	AND AL.Activity_Date >= GetDate()-7
	AND ISNULL(C.__Age,18) >= 18
	AND C.Email_Address IS NOT NULL
	AND C.Bulk_Email_Opt_Out <> 1
	AND CON.Publication_ID IS NOT NULL
	AND P.Participant_Type_ID IN (28,31,36,52,83)
	AND NOT EXISTS(SELECT * FROM dp_Contact_Publications CP
		WHERE CP.Contact_ID=C.Contact_ID
		AND CP.Publication_ID=CON.Publication_ID)

/** Ministry Smart Subscriptions **/
INSERT INTO dp_Contact_Publications(Contact_ID,Publication_ID,Unsubscribed,Domain_ID)
OUTPUT INSERTED.Contact_Publication_ID
INTO #CPInserted1
SELECT DISTINCT C.Contact_ID,M.Publication_ID,0,@DomainID
FROM Contacts C
	LEFT JOIN Participants P ON P.Contact_ID = C.Contact_ID
	LEFT JOIN Activity_Log AL ON AL.Contact_ID = C.Contact_ID
	LEFT JOIN Ministries M ON M.Ministry_ID = AL.Ministry_ID
WHERE
	AL.Ministry_ID=M.Ministry_ID
	AND AL.Activity_Date >= GetDate()-7
	AND ISNULL(C.__Age,18) >= 18
	AND C.Email_Address IS NOT NULL
	AND C.Bulk_Email_Opt_Out <> 1
	AND M.Publication_ID IS NOT NULL
	AND P.Participant_Type_ID IN (28,31,36,52,83)
	AND NOT EXISTS(SELECT * FROM dp_Contact_Publications CP
		WHERE CP.Contact_ID=C.Contact_ID
		AND CP.Publication_ID=M.Publication_ID)

/** Ministry Minors Smart Subscriptions **/
INSERT INTO dp_Contact_Publications(Contact_ID,Publication_ID,Unsubscribed,Domain_ID)
OUTPUT INSERTED.Contact_Publication_ID
INTO #CPInserted1
SELECT DISTINCT C.Contact_ID,M.Publication_ID,0,@DomainID
FROM Contacts C
	LEFT JOIN Households H ON H.Household_ID=C.Household_ID 
	LEFT JOIN Contacts C2 ON C2.Household_ID=H.Household_ID
	LEFT JOIN Activity_Log AL ON AL.Contact_ID = C2.Contact_ID
	LEFT JOIN Ministries M ON M.Ministry_ID = AL.Ministry_ID
	LEFT JOIN Participants P ON P.Contact_ID = C.Contact_ID
WHERE
	AL.Ministry_ID=M.Ministry_ID
	AND AL.Activity_Date >= GetDate()-7
	AND ISNULL(C.__Age,18) >= 18
	AND C2.__Age < 18
	AND C.Email_Address IS NOT NULL
	AND C.Bulk_Email_Opt_Out <> 1
	AND C.Household_Position_ID=1
	AND C2.Household_Position_ID=2
	AND M.Publication_ID IS NOT NULL
	AND P.Participant_Type_ID IN (28,31,36,52,83)
	AND NOT EXISTS(SELECT * FROM dp_Contact_Publications CP
		WHERE CP.Contact_ID=C.Contact_ID
		AND CP.Publication_ID=M.Publication_ID)

/** Event Smart Subscriptions **/
INSERT INTO dp_Contact_Publications(Contact_ID,Publication_ID,Unsubscribed,Domain_ID)
OUTPUT INSERTED.Contact_Publication_ID
INTO #CPInserted1
SELECT DISTINCT C.Contact_ID,E.Publication_ID,0,@DomainID
FROM Contacts C
	LEFT JOIN Participants P ON P.Contact_ID = C.Contact_ID
	LEFT JOIN Event_Participants EP ON EP.Participant_ID = P.Participant_ID
	LEFT JOIN Events E ON EP.Event_ID = E.Event_ID
WHERE
	E.Event_Start_Date >= GetDate()-7
	AND ISNULL(C.__Age,18) >= 18
	AND C.Email_Address IS NOT NULL
	AND C.Bulk_Email_Opt_Out <> 1
	AND E.Publication_ID IS NOT NULL
	AND EP.Participation_Status_ID IN (2,3,4)
	AND NOT EXISTS(SELECT * FROM dp_Contact_Publications CP
		WHERE CP.Contact_ID=C.Contact_ID
		AND CP.Publication_ID=E.Publication_ID)

/** Event Minors Smart Subscriptions **/
INSERT INTO dp_Contact_Publications(Contact_ID,Publication_ID,Unsubscribed,Domain_ID)
OUTPUT INSERTED.Contact_Publication_ID
INTO #CPInserted1
SELECT DISTINCT C.Contact_ID,E.Publication_ID,0,@DomainID
FROM Contacts C
	LEFT JOIN Households H ON C.Household_ID = H.Household_ID
	LEFT JOIN Contacts C2 ON C2.Household_ID = H.Household_ID
	LEFT JOIN Participants P ON P.Contact_ID = C2.Contact_ID
	LEFT JOIN Event_Participants EP ON EP.Participant_ID = P.Participant_ID
	LEFT JOIN Events E ON EP.Event_ID = E.Event_ID
WHERE
	E.Event_Start_Date >= GetDate()-7
	AND ISNULL(C.__Age,18) >= 18
	AND C2.__Age < 18
	AND C.Email_Address IS NOT NULL
	AND C.Bulk_Email_Opt_Out <> 1
	AND C.Household_Position_ID = 1
	AND C2.Household_Position_ID = 2
	AND E.Publication_ID IS NOT NULL
	AND EP.Participation_Status_ID IN (2,3,4)
	AND NOT EXISTS(SELECT * FROM dp_Contact_Publications CP
		WHERE CP.Contact_ID=C.Contact_ID
		AND CP.Publication_ID=E.Publication_ID)

/*** Add entries to the Audit Log for new subscribers ***/
INSERT INTO dp_Audit_Log (Table_Name,Record_ID,Audit_Description,User_Name,User_ID,Date_Time)
SELECT 'dp_Contact_Publications',#CPInserted1.Contact_Publication_ID,'Created','Svc Mngr',0,GETDATE()
FROM #CPInserted1

/** Update Bulk Opt Outs **/
UPDATE CP
SET CP.Unsubscribed = 1
OUTPUT INSERTED.Contact_Publication_ID
INTO #CPUnsubbed1
FROM dp_Contact_Publications CP
    LEFT JOIN Contacts C ON CP.Contact_ID = C.Contact_ID
WHERE CP.Unsubscribed = 0
    AND (C.Email_Address IS NULL OR C.Bulk_Email_Opt_Out = 1)
	AND (C.Mobile_Phone IS NULL OR C.Do_Not_Text = 1)

/*** Add entries to the Audit Log for unsubscribes ***/
INSERT INTO dp_Audit_Log (Table_Name,Record_ID,Audit_Description,User_Name,User_ID,Date_Time)
OUTPUT INSERTED.Audit_Item_ID, INSERTED.Record_ID
INTO #CPAuditDetail1
SELECT 'dp_Contact_Publications',#CPUnsubbed1.Contact_Publication_ID,'Updated','Svc Mngr',0,GETDATE()
FROM #CPUnsubbed1

INSERT INTO dp_Audit_Detail (Audit_Item_ID, Field_Name, Field_Label, Previous_Value, New_Value)
SELECT ALI.Audit_Item_ID,'Unsubscribed','Unsubscribed',0,1
FROM #CPAuditDetail1 ALI



/***   DELETE duplicate subscriptions to the same publication   ***/
/*** The 'Combine Contacts Tool' does not combine subscriptions ***/
DELETE Subscription_Duplicates
FROM
(
SELECT *,
	DupRank = ROW_NUMBER() OVER (
		PARTITION BY Contact_ID, Publication_ID
		ORDER BY (SELECT Unsubscribed) DESC
		)
	FROM dp_Contact_Publications
	) AS Subscription_Duplicates
	WHERE DupRank > 1;

/*** DELETE subscriptions where someone has no email address and phone number ***/
DELETE FROM dp_Contact_Publications
WHERE Contact_ID IN (SELECT DISTINCT Contact_ID FROM Contacts C WHERE (C.Email_Address = '' OR C.Email_Address IS NULL) AND (C.Mobile_Phone = '' OR C.Mobile_Phone IS NULL) AND EXISTS(SELECT * FROM dp_Contact_Publications CP WHERE CP.Contact_ID = C.Contact_ID))

/*** Drop temporary tables ***/
DROP TABLE #CPInserted1
DROP TABLE #CPUnsubbed1
DROP TABLE #CPAuditDetail1
