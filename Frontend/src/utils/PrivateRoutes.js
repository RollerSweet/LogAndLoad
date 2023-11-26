import { Outlet, Navigate } from "react-router-dom";
import axios from "axios";
import { useState, useEffect } from "react";
import { useLocation } from "react-router";
import styled from "styled-components";
import loader from "../assets/loader.gif";

const API_BASE_URL = process.env.REACT_APP_BACKEND_IP;

const IsTokenValid = async (token) => {
  const axiosInstance = axios.create({
    baseURL: `https://${API_BASE_URL}:443`,
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  try {
    const response = await axiosInstance.get("/validate_token");
    return response.data;
  } catch (error) {
    console.error(error);
    return false;
  }
};

export const useAuth = () => {
  const token = localStorage.getItem("token");
  const [auth, setAuth] = useState(null);

  useEffect(() => {
    const fetchData = async () => {
      const isValid = await IsTokenValid(token);
      setAuth(isValid);
    };
    fetchData();
  }, [token]);

  return auth;
};

const PrivateRoutes = () => {
  const isAuth = useAuth();
  const location = useLocation();

  if (isAuth === null) {
    // Render a loading indicator
    return (
      <Container>
        <img src={loader} alt="loader" className="loader" />
      </Container>
    );
  }

  return isAuth ? (
    <Outlet />
  ) : (
    <Navigate to="/login" state={{ from: location }} />
  );
};


const Container = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  gap: 3rem;
  background-color: #131324;
  height: 100vh;
  width: 100vw;

  .loader {
    max-inline-size: 100%;
  }

  .title-container {
    h1 {
      color: white;
    }
  }
  .avatars {
    display: flex;
    gap: 2rem;

    .avatar {
      border: 0.4rem solid transparent;
      padding: 0.4rem;
      border-radius: 5rem;
      display: flex;
      justify-content: center;
      align-items: center;
      transition: 0.5s ease-in-out;
      img {
        height: 6rem;
        transition: 0.5s ease-in-out;
      }
    }
    .selected {
      border: 0.4rem solid #4e0eff;
    }
  }
  .submit-btn {
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
`;


export default PrivateRoutes;
