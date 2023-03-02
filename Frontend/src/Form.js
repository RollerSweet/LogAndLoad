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
      .post('http://1:80/upload/csv', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      })
      .then((response) => {
        console.log(response.data);
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
