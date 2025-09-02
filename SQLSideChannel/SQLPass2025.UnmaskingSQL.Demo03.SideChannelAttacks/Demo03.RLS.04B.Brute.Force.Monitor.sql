/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.RLS.04B.Brute.Force.Monitor.sql
*	Notes:		Can be used to view progress of the brute force
*				RLS attack in real time
*				This is not a monitor or mitigation - only useful
*				for the person executing the attack / demonstrations
********************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

SELECT *
FROM ##RLS
GO
