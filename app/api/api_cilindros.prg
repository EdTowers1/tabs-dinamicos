function api_cilindros( oDom )

	do case
		case oDom:GetProc() == 'nuevo_cilindro'        ; DoNuevo_Cilindro( oDom )
			otherwise
			oDom:SetError( "Proc don't defined => " + oDom:GetProc())
	endcase

return oDom:Send()

// -------------------------------------------------- //


