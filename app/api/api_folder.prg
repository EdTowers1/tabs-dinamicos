function api_folder( oDom )

	do case
			case oDom:GetProc() == 'prueba'        ; DoPrueba( oDom )

			otherwise
			oDom:SetError( "Proc don't defined => " + oDom:GetProc())
	endcase

return oDom:Send()

// -------------------------------------------------- //


function DoPrueba( oDom )

	    local cHtml := ULoadHtml( '../html/views/prueba.html'  )

	    // Asignar el HTML al contenedor especificado
	    oDom:SetPanel( 'form_home_cilindros-mycontainer', cHtml )

	return nil