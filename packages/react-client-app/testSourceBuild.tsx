import React from "react";
import type { FC } from "react";
import Server from "react-dom/server";

export type ButtonProps = {
  onClick: () => void;
  label: string;
};

export const Button: FC<ButtonProps> = ({ onClick, label }) => {
  return <button onClick={onClick}>{label}</button>;
};

console.log(
  Server.renderToString(
    <Button onClick={() => console.log("hello")} label="Touch me" />
  )
);
