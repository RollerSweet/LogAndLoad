import React, { useState } from "react";
import axios from "axios";
import { useNavigate } from "react-router-dom";
import styled from "styled-components";

axios.defaults.baseURL = `https://${process.env.REACT_APP_BACKEND_IP}`; // Set the base URL for your backend API

function Form() {
  const [name, setName] = useState("");
  const [file, setFile] = useState(null);
  const [zipName, setZipName] = useState("Logs")
  const [downloading, setDownloading] = useState(false);
  const [token] = useState(localStorage.getItem("token") || "");
  const navigate = useNavigate(); // Initialize the useNavigate hook

  const handleNameChange = (event) => {
    setName(event.target.value);
    setZipName(event.target.value)
  };

  const handleFileChange = (event) => {
    const selectedFile = event.target.files[0];
    if (selectedFile && selectedFile.type === "text/csv") {
      setName("");
      setFile(selectedFile);
      setZipName(selectedFile.name.split(".")[0])
    } else {
      setFile(null);
      alert("Please select a CSV file.");
    }
  };

  axios.interceptors.request.use(
    (config) => {
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    },
    (error) => {
      return Promise.reject(error);
    }
  );

  const handleSubmit = async (event) => {
    event.preventDefault();
    setDownloading(true);
    const formData = new FormData();
    if (file) {
      formData.append("file", file, file.name);
    }
    if (name) {
      formData.append("vm_name", name);
    }

    try {
      const response = await axios.post("/upload", formData, {
        headers: {
          "Content-Type": "multipart/form-data",
        },
        responseType: "blob", // Set the response type to blob
      });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      console.log(zipName)
      link.setAttribute("download", `${zipName}-Logs.zip`);
      document.body.appendChild(link);
      link.click();
      setDownloading(false);
    } catch (error) {
      setDownloading(false);
      if (error.response && error.response.status === 401) {
        navigate("/");
      }
    }
  };

  return (
    <FormContainer>
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label>VM Name</label>
          <input
            type="text"
            value={name}
            onChange={handleNameChange}
            min="1"
            className="form-control"
            disabled={file ? true : false}
          />
        </div>
        <div className="form-group">
          <label>CSV File</label>
          <input
            type="file"
            accept=".csv"
            onChange={handleFileChange}
            className="form-control-file"
            disabled={name ? true : false}
          />
        </div>
        <button
          type="submit"
          disabled={downloading}
          className="btn btn-primary"
        >
          {downloading ? "Downloading..." : (
            "Download"
          )}
        </button>
      </form>
    </FormContainer>
  );
}
const FormContainer = styled.div`
  height: 100vh;
  width: 100vw;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 1rem;
  align-items: center;
  background-color: #131324;

  form {
    display: flex;
    flex-direction: column;
    gap: 2rem;
    background-color: #00000076;
    border-radius: 2rem;
    padding: 5rem;
    max-width: 50%;
  }

  .form-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    label {
      color: white;
      text-transform: uppercase;
      font-size: 1rem;
    }
    .form-control {
      background-color: transparent;
      padding: 1rem;
      border: 0.1rem solid #4e0eff;
      border-radius: 0.4rem;
      color: white;
      font-size: 1rem;
      &:focus {
        border: 0.1rem solid #997af0;
        outline: none;
      }
    }
    .form-control-file {
      color: white;
      background-color: transparent;
      padding: 1rem;
      border: 0.1rem solid #4e0eff;
      border-radius: 0.4rem;
      &:focus {
        outline: none;
      }
      &[value]:not([value=""]) {
        background-color: #4e0eff;
        border-color: #4e0eff;
        color: white;
      }
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
      background-color: #4e37ff;
    }
  }
  button[type="submit"]:disabled {
    background-color: #371B80;
    color: #555;
    cursor: not-allowed;
  }
`;

export default Form;
