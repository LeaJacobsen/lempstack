<?php
$conn = new mysqli("db", getenv("DB_USER"), getenv("DB_PASSWORD"), getenv("DB_NAME"));
echo $conn->connect_error ? "DB connection failed: " . $conn->connect_error : "It works! Connected to the database.";
