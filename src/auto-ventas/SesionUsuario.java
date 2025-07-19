/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package autoventasbd2kevinramirez;

import java.sql.Connection;
import java.sql.SQLException;
/**
 *
 * @author kevin
 */
public class SesionUsuario {
    public static String usuario;
    public static String contrasena;
    public static String rol;
    public static Connection conexion;
    
    public static void cerrarSesion() {
        try {
            if (conexion != null && !conexion.isClosed()) {
                conexion.close();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            usuario = null;
            contrasena = null;
            rol = null;
            conexion = null;
        }
    }
    
}
