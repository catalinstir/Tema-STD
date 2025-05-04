package com.chat;

import java.io.*;
import java.util.*;
import javax.websocket.*;
import javax.websocket.server.*;
import java.sql.*;

@ServerEndpoint("/chat")
public class WebSocketChatServer {
    private static final Set<Session> sessions = Collections.synchronizedSet(new HashSet<>());
    private static final String DB_URL = "jdbc:mysql://localhost:3306/chat";
    private static final String DB_USER = "chatuser";
    private static final String DB_PASSWORD = "chatpassword";
    
    @OnOpen
    public void onOpen(Session session) {
        sessions.add(session);
        try {
            // Send chat history to new user
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            String sql = "SELECT username, message, timestamp FROM messages ORDER BY timestamp DESC LIMIT 50";
            PreparedStatement stmt = conn.prepareStatement(sql);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                String username = rs.getString("username");
                String message = rs.getString("message");
                String timestamp = rs.getString("timestamp");
                session.getBasicRemote().sendText("{\"username\":\"" + username + "\",\"message\":\"" + message + "\",\"timestamp\":\"" + timestamp + "\"}");
            }
            
            rs.close();
            stmt.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    @OnMessage
    public void onMessage(String message, Session session) {
        try {
            // Parse message JSON
            // For simplicity, assume format is {"username":"name","message":"text"}
            String username = message.split("\"username\":\"")[1].split("\"")[0];
            String text = message.split("\"message\":\"")[1].split("\"")[0];
            
            // Save to database
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            String sql = "INSERT INTO messages (username, message, timestamp) VALUES (?, ?, NOW())";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, username);
            stmt.setString(2, text);
            stmt.executeUpdate();
            stmt.close();
            conn.close();
            
            // Broadcast message to all connected clients
            for (Session s : sessions) {
                s.getBasicRemote().sendText(message);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    @OnClose
    public void onClose(Session session) {
        sessions.remove(session);
    }
}
