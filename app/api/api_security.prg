function Api_Security( oDom )

	//	All user need acces to login... Only we check others procs...

	if oDom:GetProc() != 'login'
	
		//	Auth system...
		
		if ! Authorization()
			retu nil
		endif
			
		//	-------------------------
	
	endif

	do case	
		
		case oDom:GetProc() == 'login'			; Login( oDom )								

			otherwise 				
			oDom:SetError( "Proc don't defined => " + oDom:GetProc())
	endcase
	
retu oDom:Send()	

// -------------------------------------------------- //

static function Login( oDom )

	local cUser 	:= oDom:Get( 'user' )
	local cPsw 		:= oDom:Get( 'password' )
	local hData		:= {=>}
	local lAccess	:= .f.
	local oUser, hRow
	local cError 	:= 'User/Password is wrong !'
	
	//	Validate parameters
	
	if len( cUser ) > 10 
		oDom:SetMsg( 'User too long. Max. 10 characters' )
		oDom:Focus( 'user' )
		retu nil
	endif
		
	if empty( cUser ) 
		oDom:SetMsg( 'User is empty' )
		oDom:Focus( 'user' )
		retu nil
	endif		
		
	if empty( cPsw ) 
		oDom:SetMsg( 'Psw is empty' )
		oDom:Focus( 'password' )
		retu nil
	endif

	//	Process - Usuario de prueba fijo
	
	if cUser == 'admin' .and. cPsw == '1234'
			
		lAccess := .t.
	
		hData[ 'user' ] := cUser
		hData[ 'name' ] := 'Administrador'
		hData[ 'profile' ] := 'A'					
		
		USessionStart()
		Usession( 'credentials', hData )
		URedirect( '/' )
					
	endif
		
	if !lAccess
		oDom:SetError( cError )			
		retu nil					
	endif
		
retu nil

// -------------------------------------------------- //
//	FUNCTIONS - NO API
//	------------------------------------------------- //

function Upd_Info()
	
	local cHtml 			:= ''
	local hCredentials, oSession

	if ! USessionReady()
		URedirect( 'Login' )
		retu nil
	endif
	
	hCredentials := USession( 'credentials' )
	
	oSession := UGetSession()		
	
	cHtml := ULoadHtml( 'functional\upd_info.html', hCredentials, oSession )
	
	UWrite( cHtml )									

retu nil

// -------------------------------------------------- //

function Logout()

	USessionEnd()
	
	URedirect( 'login' )

retu nil 

// -------------------------------------------------- //
