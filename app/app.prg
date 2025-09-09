#include '../lib/uhttpd2/uhttpd2.ch'

REQUEST DBFCDX

//	-----------------------
//REQUEST HB_CODEPAGE_ES850
//REQUEST HB_LANG_ES
//REQUEST HB_CODEPAGE_ESWIN
//REQUEST HB_CODEPAGE_UTF8EX
//REQUEST HB_CODEPAGE_UTF8

//	-----------------------

REQUEST MEMOREAD

#define VK_ESCAPE	27

function main()

	Config()

	hb_threadStart( @WebServer() )

	while inkey(0) != VK_ESCAPE
	end

retu nil

//----------------------------------------------------------------------------//

function WebServer()

	local oServer 	:= Httpd2()

	oServer:SetPort( 86 )
	oServer:SetDirFiles( 'examples', .T. )		//	.t. == Index list

	//oServer:SetDirFiles( 'data.repository' )
	oServer:bInit := {|hInfo| ShowInfo( hInfo ), OpenUrl( hInfo ) }

	/*	Example Charset UTF8. Active to .T. Default .f.
		oServer:lUtf8 := .T. */

	//	Config Sessions !
	//	-----------------
	oServer:cSessionPath			:=	'.sessions' 	//	Default path session ./sessions
	oServer:cSessionName			:=	'USESSID' 		//	Default session name USESSID
	oServer:cSessionPrefix		:=	'sess_'			//	Default prefix sess_
	oServer:cSessionSeed			:= 	'm!PaswORD@'	//	Password default ...

	oServer:nSessionDuration	:= 900		//	Session duration set to 15 minutes (900 seconds)
	oServer:nSessionGarbage		:=	1000			//	Default totals sessions executed for garbage
	oServer:nSessionLifeDays	:=	3				//	Default days stored for garbage 3
	oServer:lSessionCrypt			:=	.F. 			//	Default crypt session .F.

	//	oServer:nSessionDuration	:=	10				//	(for check sessions example, only 10sec.)



	// ---------------- Rutas para vistas ----------------

	oServer:Route( '/'								, '../html/main.html' )
	oServer:Route( 'login'						, '../html/security/login.html' )
	oServer:Route( 'recepcion'						, '../html/views/home_cilindros.html' )
	oServer:Route( 'nuevocilindro'				, '../html/modulos/recepcion_cilindros.html')
	oServer:Route( 'prueba'						, '../html/views/prueba.html' )


	// ---------------- Rutas para funciones ----------------
	oServer:Route( 'logout'						, 'logout' ) 





	//	-----------------------------------------------------------------------//
	*/
	IF ! oServer:Run()

		? "=> Server error:", oServer:cError

		RETU 1
	ENDIF

RETURN 0

//----------------------------------------------------------------------------//

function ShowInfo( hInfo )

	local cLang := hb_oemtoansi(hb_langName())
	Local oConnection
	Local oDom

	HB_HCaseMatch( hInfo, .f. )

	// oConnection:=Conect_mysql(oDom, hInfo)


	CConsole '---------------------------------'
	Console  'Server Harbour9000 was started...'
	Console  '---------------------------------'
	Console  'Version httpd2..: ' + hInfo[ 'version' ]
	Console  'TWeb Version....: ' + TWebVersion()
	Console  'Start...........: ' + hInfo[ 'start' ]
	Console  'Port............: ' + ltrim(str(hInfo[ 'port' ]))
	Console  'OS..............: ' + OS()
	Console  'Harbour.........: ' + VERSION() + ' - ' + HB_BUILDDATE() + ' - ' + HB_COMPILER()
	Console  'SSL.............: ' + if( hInfo[ 'ssl' ], 'Yes', 'No' )
	Console  'Trace...........: ' + if( hInfo[ 'debug' ], 'Yes', 'No' )
	Console  'Codepage........: ' + hb_SetCodePage() + '/' + hb_cdpUniID( hb_SetCodePage() )
	Console  'UTF8 (actived)..: ' + if( hInfo[ 'utf8' ], 'Yes', 'No' )
	/*IF ! hInfo[ 'db' ]
		//Console 'Connection OK '
		Console 'Host............: ' + oConnection:cHost
		Console 'Database........: ' + oConnection:cDBName
		Console 'Version Mysql.3..: '  + oConnection:GetServerInfo()
		//Console 'Version MariadbC:'  + oConnection:GetClientInfo()
		//Console 'Cuantas Cuentas :'  + Alltrim(Str(adatos[1]))
		//Console 'Json........... :'  + Hb_jsonEncode(adatos[2])
		oConnection:End()
	ENDIF
	*/
	Console  Replicate( '-', len( cLang ) )
	Console  cLang
	Console  Replicate( '-', len( cLang ) )
	Console  'Escape for exit...'

retu nil

//----------------------------------------------------------------------------//

function Config()

   	REQUEST HB_LANG_ES
	REQUEST HB_CODEPAGE_ESMWIN

    SET Deleted  ON
    SET CENTURY  ON
    SET TIME FORMAT TO "hh:mm"
    SET Date     TO ANSI
    SET EPOCH    TO 1960
    SET DECIMALS TO 2
    SET CONFIRM  OFF
    SET EXACT    ON

	RddSetDefault( 'DBFCDX' )
   	HB_Langselect("ES")
   	HB_CDPSelect("ESMWIN")


retu nil

//----------------------------------------------------------------------------//

#define SW_SHOW             5

static function OpenUrl( hInfo )

	local cUrl := ''

	cUrl := if( hInfo[ 'ssl' ], 'https://localhost', 'http://localhost' )

	if hInfo[ 'port' ] != 80
		cUrl += ':' + ltrim(str( hInfo[ 'port' ] ))
	endif
	#ifdef 	__PLATFORM__WINDOWS
	WAPI_ShellExecute( nil, "open", cUrl, nil, nil, SW_SHOW )
	#else
	? 'Pending...'
	#endif

retu nil

// -------------------------------------------------- //
function Conect_database(oDom,hInfo)
	Local oErr
	Local hParms:=Loadini()

    IF  hParms['lerror']
        hInfo['lerror']         :=  .t.
        hInfo['lerrordetalle']  :=  hParms['lerrordetalle']
		//? hb_dumpvar( hInfo['lerrordetalle'] )
        return nil
    endif


	TRY
		hInfo['db']:=TDolphinSrv():New(hParms["host"]       ,;
			hParms["user"]       ,;
			hParms["psw"]        ,;
			val(hParms["port"])  ,;
			val(hParms["flags"]) ,;
			hParms["dbname"] )
            hInfo['lerror']         :=  .f.
            hInfo['lerrordetalle']  :=  ""

	CATCH oErr
            hInfo['lerror']         :=  .t.
            hInfo['lerrordetalle']  :=  "No pudo conectar al servidor Sql  "  //+ hb_dumpvar( oErr )

//? hb_dumpvar( oErr )

	END

RETURN NIL



// -------------------------------------------------- //
Static function Loadini()

Local oErr
Local c := "mariadb"
Local hParms := {=>}
Local hini

	TRY
        hIni   := HB_ReadIni( "connect.ini" )
        hParms['host']          :=  hIni[ c ]["host"]
        hParms['user']          :=  hIni[ c ]["user"]
        hParms['psw']           :=  hIni[ c ]["psw"]
        hParms['port']          :=  hIni[ c ]["port"]
        hParms['flags']         :=  hIni[ c ]["flags"]
        hParms['dbname']        :=  hIni[ c ]["dbname"]
        hParms['lerror']        :=  .f.
        hParms['lerrordetalle'] :=	""
    CATCH oErr
        hParms['lerror']         :=  .T.
        hParms['lerrordetalle']  :=  "No se pudo abrir configuración, "  //+  hb_dumpvar( oErr )
        //? hb_dumpvar( oErr )
    End

RETURN (hParms)
