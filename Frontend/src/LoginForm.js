import React, { useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
// import "./LoginForm.css";
import styled from "styled-components";
import Logo from "./assets/logo.svg";

const BACKEND_SERVER = process.env.REACT_APP_BACKEND_IP;

const LoginForm = () => {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(null);
  const [loggingin, setLoggingin] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  const handleSubmit = async (event) => {
    event.preventDefault();
    setLoggingin(true);
    try {
      const response = await fetch(`https://${BACKEND_SERVER}/api/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });

      const data = await response.json();
      if (response.ok) {
        localStorage.setItem("token", data.access_token);
        setError("You have logged in!");
        setLoggingin(false);
        if (location.state?.from) {
          navigate(location.state.from);
        }
      } else {
        setError(response.statusText);
        setLoggingin(false);
      }
    } catch (error) {
      setError("There was an error logging in. Please try again.");
      setLoggingin(false);
    }
  };

  return (
    <>
      <FormContainer>
        <form className="login-form" onSubmit={handleSubmit}>
          <div className="brand">
            <img src={Logo} alt="logo" />
            <h1>log&load</h1>
          </div>
          <input
            type="text"
            id="username"
            placeholder="Username"
            min="3"
            value={username}
            onChange={(event) => setUsername(event.target.value)}
            className="login-input"
          />
          <input
            type="password"
            id="password"
            placeholder="Password"
            min="3"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className="login-input"
          />
          <button disabled={loggingin} type="submit" className="login-button">
            {loggingin ? "Logging in..." : "Login"}
          </button>
          <span>Welcome to the Log & Load</span>
          <span style={{fontSize: "0.8em", color: "#43688B"}}>Made By Tamir & Tomer</span>
          {error && <p>{error}</p>}
        </form>
      </FormContainer>
    </>
  );
};
const FormContainer = styled.div`
  height: 100vh;
  width: 100vw;
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  gap: 1rem;
  background-color: #131324;

  .brand {
    display: flex;
    align-items: center;
    gap: 1rem;
    justify-content: center;

    img {
      height: 5rem;
    }

    h1 {
      color: white;
      text-transform: uppercase;
    }
  }

  form {
    display: flex;
    flex-direction: column;
    gap: 2rem;
    background-color: #00000076;
    border-radius: 2rem;
    padding: 5rem;
  }

  input {
    background-color: transparent;
    padding: 1rem;
    border: 0.1rem solid #4e0eff;
    border-radius: 0.4rem;
    color: white;
    width: 88%;
    font-size: 1rem;

    &:focus {
      border: 0.1rem solid #997af0;
      outline: none;
    }
  }

  button {
    background-color: #4e0eff;
    color: white;
    padding: 1rem 2rem;
    border: none;
    font-weight: bold;
    cursor: pointer;
    border-radius: 0.4rem;
    font-size: 1rem;
    text-transform: uppercase;

    &:hover {
      background-color: #4e0eff;
    }
  }

  span {
    color: white;
    text-transform: uppercase;
    text-align: center;

    a {
      color: #4e0eff;
      text-decoration: none;
      font-weight: bold;
    }
  }
  
  p {
    color: red;
    word-wrap: break-word;
    text-align: center;
    font-weight: bold;
  }
`;

export default LoginForm;
