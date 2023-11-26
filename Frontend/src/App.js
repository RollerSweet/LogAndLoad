import { Route, Routes } from "react-router-dom";
import Form from "./Form";
import LoginForm from "./LoginForm";
import NotFound from "./NotFound";
import PrivateRoutes from "./utils/PrivateRoutes";

function App() {
  return (
    <>
      <Routes>
        <Route path="/login" element={<LoginForm />} />
        <Route element={<PrivateRoutes />}>
          <Route path="/" element={<Form />} exact />
          <Route path="*" element={<NotFound />} />
        </Route>
      </Routes>
    </>
  );
}

export default App;
