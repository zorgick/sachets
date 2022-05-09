import React from "react";
import type { FC } from "react";

export type ButtonProps = {
  onClick: () => void;
  label: string;
};

export const Button: FC<ButtonProps> = ({ onClick, label }) => {
  return <button onClick={onClick}>{label}</button>;
};
