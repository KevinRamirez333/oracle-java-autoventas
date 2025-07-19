/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package autoventasbd2kevinramirez;

import javax.swing.JOptionPane;

/**
 *
 * @author kevin
 */
public class Navegacion {
     public static void mostrarMenuPrincipalPorRol() {
        switch (SesionUsuario.rol) {
            case "ROL_DUENIO" -> new MainDuenio().setVisible(true);
            case "ROL_SUPERVISOR" -> new MainSupervisor().setVisible(true);
            case "ROL_VENDEDOR" -> new MainVendedor().setVisible(true);
            default -> JOptionPane.showMessageDialog(null, "Rol no reconocido.");
        }
    }
    
}
