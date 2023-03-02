import React, { useState } from 'react';
import axios from 'axios';
import './Form.css';

function Form() {
  const [name, setName] = useState('');
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);

  const handleNameChange = (event) => {
    setName(event.target.value);
  };

  const handleFileChange = (event) => {
    const selectedFile = event.target.files[0];
    if (selectedFile && selectedFile.type === 'text/csv') {
      setName('');
      setFile(selectedFile);
    } else {
      setFile(null);
      alert('Please select a CSV file.');
    }
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    setUploading(true);
    const formData = new FormData();
    if (file) {
      formData.append('file', file, file.name);
    }
    if (name) {
      formData.append('vm_name', name);

    }
   
    axios
      .post('http://localhost:80/upload/csv', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        responseType: 'blob', // Set the response type to blob
      })
      .then((response) => {
        console.log(response);
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', 'file.csv');
        document.body.appendChild(link);
        link.click();
        setUploading(false);
      })
      .catch((error) => {
        console.log(error);
        setUploading(false);
      });
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="name">Enter VM name:</label>
        <input
          type="text"
          id="name"
          placeholder="Enter VM name"
          value={name}
          onChange={handleNameChange}
          disabled={file !== null}
        />
      </div>
      <div>
        <label htmlFor="file">Upload CSV file:</label>
        <input
          type="file"
          id="file"
          accept=".csv"
          onChange={handleFileChange}
          disabled={name.trim() !== ''}
        />
      </div>
      <button type="submit" disabled={uploading || (name.trim() === '' && file === null)}>
        {uploading ? 'Uploading...' : 'Submit'}
      </button>
    </form>
  );
}

export default Form;
