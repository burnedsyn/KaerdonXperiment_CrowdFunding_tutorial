/** @type {import('tailwindcss').Config} */
module.exports = {

  content: [
 
    "./src/**/*.{js,jsx,ts,tsx}",
 
  ],
 
  theme: {
    colors: {
      primary: '#000000' ,
      secondary:'#070c15ad' ,
      third: '#ced0d5',
      fourth: '#6c129650',      
      fifth: '#ede8e4',
      sixth:'#8a8381',
      seventh:'#c8c7c9',
      eight: '#c1afa8',
      nine: '#1DC071',
      white: '#ffffff',
    },
    extend: {
      fontFamily: {
        epilogue: ['Epilogue', 'sans-serif'],
      },
      boxShadow: {
        'custom':'-3px -3px 8px 5px #51beef33',
      }
      }
  },
 
  plugins: [],
 
 }